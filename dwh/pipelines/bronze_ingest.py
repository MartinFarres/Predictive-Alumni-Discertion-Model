from __future__ import annotations

import os
from pathlib import Path
from datetime import datetime

import dlt
import duckdb

from dwh.sources.sql_sources import guarani_multi_source


def default_duckdb_path() -> Path:
	dwh_dir = Path(__file__).resolve().parents[1]
	return dwh_dir / "data" / "warehouse.duckdb"


def _ensure_valid_duckdb_file(duckdb_path: Path) -> None:
	"""Ensure DuckDB file is usable.

	If a file exists but is not a valid DuckDB database, rename it aside and
	create a fresh database file.
	"""
	if not duckdb_path.exists():
		return
	try:
		with duckdb.connect(str(duckdb_path)) as conn:
			conn.execute("SELECT 1")
	except Exception as exc:  # noqa: BLE001
		ts = datetime.now().strftime("%Y%m%d%H%M%S")
		bad_path = duckdb_path.with_name(f"{duckdb_path.stem}.invalid.{ts}{duckdb_path.suffix}")
		duckdb_path.rename(bad_path)
		print(f"[Bronze][WARN] Invalid DuckDB file moved to: {bad_path} ({exc})")
		with duckdb.connect(str(duckdb_path)) as conn:
			conn.execute("SELECT 1")


def run_bronze(*, source_dbs: list[dict[str, str]], duckdb_path: Path | None = None) -> None:
	duckdb_path = duckdb_path or default_duckdb_path()
	duckdb_path.parent.mkdir(parents=True, exist_ok=True)
	_ensure_valid_duckdb_file(duckdb_path)

	# dlt reads destination credentials from config/env.
	# For DuckDB, the credential is the database file path.
	os.environ.setdefault("DESTINATION__DUCKDB__CREDENTIALS", str(duckdb_path))

	# Keep resource execution conservative by default to reduce memory pressure.
	# Users can override these via environment variables.
	os.environ.setdefault("DLT__EXTRACT__WORKERS", "1")
	os.environ.setdefault("DLT__NORMALIZE__WORKERS", "1")
	os.environ.setdefault("DLT__LOAD__WORKERS", "1")

	pipeline = dlt.pipeline(
		pipeline_name="padm_dwh",
		destination="duckdb",
		dataset_name="bronze",
		progress="log",
	)

	source = guarani_multi_source(source_dbs)

	# Run resources one-by-one to avoid large concurrent load jobs.
	# Optionally filter via `DWH_BRONZE_RESOURCES=students,personas,...`
	requested = os.getenv("DWH_BRONZE_RESOURCES", "").strip()
	if requested:
		names = [n.strip() for n in requested.split(",") if n.strip()]
		resources = [getattr(source, n) for n in names]
	else:
		resources = list(source)

	for res in resources:
		print(f"[Bronze] Running resource: {res.name}")
		# Do NOT use pipeline.run here: it calls load() with default workers=20,
		# which can spike memory and get OOM-killed on large loads.
		pipeline.extract(res, workers=4, max_parallel_items=8, write_disposition="replace")
		pipeline.normalize(workers=2)
		pipeline.load(workers=2)
		print(f"[Bronze] Done: {res.name}")


def main() -> None:
	from dwh import config

	run_bronze(source_dbs=config.SOURCE_DATABASES)


if __name__ == "__main__":
	main()
