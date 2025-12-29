# DWH (dlt + DuckDB)

This folder contains the local Data Warehouse (DWH) pipeline using:

- **dlt** for ingestion (Bronze)
- **DuckDB** as the local warehouse storage (`data/warehouse.duckdb`)
- **SQL files** for transformations (Silver/Gold)

## Folder layout

- `data/warehouse.duckdb`: local DuckDB file
- `pipelines/bronze_ingest.py`: Source DB -> dlt -> DuckDB (bronze dataset)
- `pipelines/silver_transform.py`: runs `sql/silver/*.sql` into DuckDB (silver schema)
- `pipelines/gold_aggregates.py`: runs `sql/gold/*.sql` into DuckDB (gold schema)
- `sources/sql_sources.py`: dlt sources/resources for extraction
- `main.py`: orchestrates Bronze -> Silver -> Gold

## Configuration

Copy `config.example.py` to `config.py` and configure `SOURCE_DATABASES`.

NEXT: Move credentials into `.dlt/secrets.toml` SEE: dlt docs.

## Run

From the repo root:

- `python -m dwh.main` (runs Bronze -> Silver -> Gold)

Or run individual stages:

- `python -m dwh.pipelines.bronze_ingest`
- `python -m dwh.pipelines.silver_transform`
- `python -m dwh.pipelines.gold_aggregates`
