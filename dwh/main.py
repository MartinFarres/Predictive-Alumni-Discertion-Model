from __future__ import annotations

from dwh.pipelines.bronze_ingest import run_bronze
from dwh.pipelines.gold_aggregates import run_gold
from dwh.pipelines.silver_transform import run_silver


def main() -> None:
	from dwh import config

	run_bronze(source_dbs=config.SOURCE_DATABASES)
	run_silver()
	run_gold()


if __name__ == "__main__":
	main()
