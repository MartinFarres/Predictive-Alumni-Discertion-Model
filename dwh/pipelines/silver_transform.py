from __future__ import annotations

from pathlib import Path

from dwh.pipelines._sql_runner import default_duckdb_path, run_sql_dir


def run_silver(*, duckdb_path: Path | None = None) -> None:
	duckdb_path = duckdb_path or default_duckdb_path()
	dwh_dir = Path(__file__).resolve().parents[1]
	run_sql_dir(duckdb_path=duckdb_path, sql_dir=dwh_dir / "sql" / "silver", schema="silver")


def main() -> None:
	run_silver()


if __name__ == "__main__":
	main()
