from __future__ import annotations

from pathlib import Path

import duckdb


def default_duckdb_path() -> Path:
    dwh_dir = Path(__file__).resolve().parents[1]
    return dwh_dir / "data" / "warehouse.duckdb"


def _split_sql_statements(sql_text: str) -> list[str]:
    # Minimal statement splitter; good enough for typical transformation scripts.
    # If you start using semicolons inside strings, replace with a real SQL parser.
    statements = []
    for part in sql_text.split(";"):
        stmt = part.strip()
        if stmt:
            statements.append(stmt)
    return statements


def run_sql_dir(*, duckdb_path: Path, sql_dir: Path, schema: str) -> None:
    sql_dir = sql_dir.resolve()
    if not sql_dir.exists():
        print(f"[SQL] Directory not found: {sql_dir}")
        return

    sql_files = sorted([p for p in sql_dir.iterdir() if p.is_file() and p.suffix.lower() == ".sql"])
    if not sql_files:
        print(f"[SQL] No .sql files in {sql_dir} (nothing to do)")
        return

    with duckdb.connect(str(duckdb_path)) as conn:
        conn.execute(f"CREATE SCHEMA IF NOT EXISTS {schema}")
        conn.execute(f"SET schema '{schema}'")

        for path in sql_files:
            sql_text = path.read_text(encoding="utf-8")
            for stmt in _split_sql_statements(sql_text):
                conn.execute(stmt)
            print(f"[SQL] Executed: {path.name}")
