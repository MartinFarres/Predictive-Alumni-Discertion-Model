# DWH Architecture Documentation

## Overview

The PADM (Predictive Alumni Desertion Model) Data Warehouse is a modern analytics pipeline designed to support student dropout prediction using machine learning. The system follows the **Medallion Architecture** pattern (Bronze → Silver → Gold) to ensure data quality, traceability, and separation of concerns.

## Technology Stack

| Component               | Technology            | Version | Purpose                   |
| ----------------------- | --------------------- | ------- | ------------------------- |
| **Ingestion**           | dlt (data load tool)  | ≥1.6.0  | Declarative ELT framework |
| **Storage**             | DuckDB                | ≥1.0.0  | Embedded OLAP database    |
| **Transformations**     | SQL                   | -       | Schema transformations    |
| **Source Connectivity** | SQLAlchemy + psycopg2 | ≥2.0    | PostgreSQL connections    |
| **Language**            | Python                | ≥3.10   | Pipeline orchestration    |

## System Architecture

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                           SOURCE SYSTEMS                                        │
├─────────────────────┬──────────────────────────┬───────────────────────────────┤
│   SIU Guaraní       │        Moodle            │      Other Sources            │
│   (PostgreSQL)      │      (PostgreSQL)        │                               │
│   ─────────────     │      ───────────         │                               │
│   • Alumnos         │      • Attendance        │                               │
│   • Personas        │      • Engagement        │                               │
│   • Materias        │                          │                               │
│   • Calificaciones  │                          │                               │
└──────────┬──────────┴────────────┬─────────────┴───────────────────────────────┘
           │                       │
           ▼                       ▼
┌────────────────────────────────────────────────────────────────────────────────┐
│                              BRONZE LAYER                                       │
│                         (Raw Data Landing Zone)                                 │
│  ─────────────────────────────────────────────────────────────────────────────  │
│  Schema: bronze                                                                 │
│  Storage: DuckDB (warehouse.duckdb)                                             │
│  ─────────────────────────────────────────────────────────────────────────────  │
│  Tables:                                                                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐                │
│  │  students   │ │  personas   │ │  academic   │ │  attendance │                │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘                │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐        │
│  │   census    │ │   dropout   │ │  elementos  │ │ historia_academica  │        │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────────────┘        │
│  ┌──────────────────┐ ┌────────────────────┐ ┌───────────────────────┐          │
│  │ exam_inscriptions│ │ course_inscriptions│ │    reinscripciones    │          │
│  └──────────────────┘ └────────────────────┘ └───────────────────────┘          │
└────────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ SQL Transformations
                                    ▼
┌────────────────────────────────────────────────────────────────────────────────┐
│                              SILVER LAYER                                       │
│                    (Cleaned, Conformed Data - Star Schema)                      │
│  ─────────────────────────────────────────────────────────────────────────────  │
│  Schema: silver                                                                 │
│  Pattern: Dimensional Model (Star Schema)                                       │
│  ─────────────────────────────────────────────────────────────────────────────  │
│                                                                                 │
│  DIMENSIONS (01-09):                                                            │
│  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐ ┌────────────────┐   │
│  │   dim_fecha    │ │  dim_periodo   │ │ dim_propuesta  │ │ dim_facultad   │   │
│  └────────────────┘ └────────────────┘ └────────────────┘ └────────────────┘   │
│  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐ ┌────────────────┐   │
│  │dim_plan_version│ │  dim_elemento  │ │ dim_instancia  │ │ dim_ubicacion  │   │
│  └────────────────┘ └────────────────┘ └────────────────┘ └────────────────┘   │
│  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐                       │
│  │  dim_persona   │ │   dim_census   │ │  dim_student   │                       │
│  └────────────────┘ └────────────────┘ └────────────────┘                       │
│                                                                                 │
│  FACTS (20-29):                                                                 │
│  ┌─────────────────────────┐ ┌─────────────────────────┐ ┌─────────────────────┐│
│  │  fact_course_enrollment │ │fact_academic_performance│ │fact_exam_inscription││
│  └─────────────────────────┘ └─────────────────────────┘ └─────────────────────┘│
│  ┌─────────────────────────┐ ┌─────────────────────────┐ ┌─────────────────────┐│
│  │    fact_attendance      │ │   fact_reinscription    │ │    fact_dropout     ││
│  └─────────────────────────┘ └─────────────────────────┘ └─────────────────────┘│
│  ┌───────────────────────────┐                                                  │
│  │fact_student_status_history│                                                  │
│  └───────────────────────────┘                                                  │
└────────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ SQL Aggregations
                                    ▼
┌────────────────────────────────────────────────────────────────────────────────┐
│                               GOLD LAYER                                        │
│                    (Business-Ready Aggregations & Features)                     │
│  ─────────────────────────────────────────────────────────────────────────────  │
│  Schema: gold                                                                   │
│  ─────────────────────────────────────────────────────────────────────────────  │
│                                                                                 │
│  DATA MARTS (01-09) - Reusable Business Aggregations:                           │
│  ┌──────────────────────────┐ ┌──────────────────────────┐                      │
│  │mart_student_academic_    │ │  mart_student_engagement │                      │
│  │       summary            │ │                          │                      │
│  └──────────────────────────┘ └──────────────────────────┘                      │
│  ┌──────────────────────────┐ ┌──────────────────────────┐                      │
│  │mart_student_risk_features│ │   mart_cohort_analysis   │                      │
│  └──────────────────────────┘ └──────────────────────────┘                      │
│                                                                                 │
│  TFT FEATURE STORE (10-19) - ML-Specific Features:                              │
│  ┌──────────────────────────┐ ┌──────────────────────────┐                      │
│  │ gold_tft_static_features │ │gold_tft_temporal_features│                      │
│  └──────────────────────────┘ └──────────────────────────┘                      │
│  ┌──────────────────────────┐ ┌──────────────────────────┐                      │
│  │  gold_tft_known_future   │ │gold_tft_training_dataset │                      │
│  └──────────────────────────┘ └──────────────────────────┘                      │
└────────────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    ▼                               ▼
          ┌─────────────────┐             ┌─────────────────┐
          │   Dashboard     │             │   TFT Model     │
          │   (Dash/Plotly) │             │   (PyTorch)     │
          └─────────────────┘             └─────────────────┘
```

## Data Flow

### Pipeline Execution Order

```
┌─────────────────────────────────────────────────────────────────┐
│                    ORCHESTRATION (main.py)                       │
│                                                                  │
│  1. run_bronze()  ──▶  2. run_silver()  ──▶  3. run_gold()      │
└─────────────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

| Layer      | Responsibility        | Write Disposition | Transformation          |
| ---------- | --------------------- | ----------------- | ----------------------- |
| **Bronze** | Raw data capture      | Replace/Append    | None (1:1 copy)         |
| **Silver** | Data conformance      | Replace           | SQL (CREATE OR REPLACE) |
| **Gold**   | Business aggregations | Replace           | SQL (CREATE OR REPLACE) |

## Directory Structure

```
dwh/
├── data/
│   └── warehouse.duckdb          # DuckDB database file
├── docs/
│   ├── ARCHITECTURE.md           # This document
│   ├── BRONZE_CATALOG.md         # Bronze layer documentation
│   ├── SILVER_CATALOG.md         # Silver layer documentation
│   ├── GOLD_CATALOG.md           # Gold layer documentation
│   └── DATA_LINEAGE.md           # Source-to-target mappings
├── pipelines/
│   ├── __init__.py
│   ├── _sql_runner.py            # SQL execution utility
│   ├── bronze_ingest.py          # Bronze layer pipeline
│   ├── silver_transform.py       # Silver layer pipeline
│   └── gold_aggregates.py        # Gold layer pipeline
├── sources/
│   ├── __init__.py
│   └── sql_sources.py            # dlt source definitions
├── sql/
│   ├── bronze/                   # Source extraction queries
│   ├── silver/                   # Dimension & fact definitions
│   └── gold/                     # Mart & feature definitions
├── config.example.py             # Configuration template
├── config.py                     # Active configuration (gitignored)
├── main.py                       # Pipeline orchestrator
├── requirements.txt              # Python dependencies
└── README.md                     # Quick start guide
```

## Naming Conventions

### File Naming

| Pattern                    | Layer  | Example                                             |
| -------------------------- | ------ | --------------------------------------------------- |
| `{table_name}.sql`         | Bronze | `students.sql`, `academic.sql`                      |
| `{NN}_{type}_{name}.sql`   | Silver | `01_dim_fecha.sql`, `20_fact_course_enrollment.sql` |
| `{NN}_{prefix}_{name}.sql` | Gold   | `01_mart_student_academic_summary.sql`              |

### Table Naming

| Prefix      | Type         | Reusable | Example                      |
| ----------- | ------------ | -------- | ---------------------------- |
| `dim_`      | Dimension    | Yes      | `dim_student`, `dim_persona` |
| `fact_`     | Fact table   | Yes      | `fact_academic_performance`  |
| `mart_`     | Data mart    | Yes      | `mart_student_risk_features` |
| `gold_tft_` | TFT features | No       | `gold_tft_training_dataset`  |

### Numeric Prefixes

| Range | Silver Purpose | Gold Purpose |
| ----- | -------------- | ------------ |
| 01-09 | Dimensions     | Data Marts   |
| 10-19 | (Reserved)     | TFT Features |
| 20-29 | Fact Tables    | (Reserved)   |

## Incremental Loading Strategy

The Bronze layer supports two loading strategies:

### Full Refresh (Replace)

Used for small, frequently changing reference tables.

```python
write_disposition="replace"
```

**Tables**: `students`, `personas`, `elementos`, `instancias`, `attendance`

### Incremental Append

Used for large event/history tables to avoid full reloads.

```python
write_disposition="append"
cursor_column="fecha_nota"
initial_value=date(1900, 1, 1)
```

**Tables**: `academic`, `census`, `dropout`, `historia_academica`, `exam_inscriptions`, `course_inscriptions`, `reinscripciones`

## Configuration

### Source Database Configuration

```python
# config.py
SOURCE_DATABASES = [
    {
        "name": "guarani_prod",
        "conn_string": "postgresql://user:pass@host:5432/db"
    },
    {
        "name": "guarani_sede2",
        "conn_string": "postgresql://user:pass@host2:5432/db"
    }
]
```

### Environment Variables

| Variable                     | Default    | Description                              |
| ---------------------------- | ---------- | ---------------------------------------- |
| `DWH_BRONZE_RESOURCES`       | (all)      | Comma-separated list of resources to run |
| `DWH_INCREMENTAL_START_DATE` | 1900-01-01 | Override start date for initial backfill |
| `DLT__EXTRACT__WORKERS`      | 1          | Number of extraction workers             |
| `DLT__NORMALIZE__WORKERS`    | 1          | Number of normalization workers          |
| `DLT__LOAD__WORKERS`         | 1          | Number of load workers                   |

## Execution

### Full Pipeline

```bash
python -m dwh.main
```

### Individual Layers

```bash
# Bronze only (extract from sources)
python -m dwh.pipelines.bronze_ingest

# Silver only (dimensional model)
python -m dwh.pipelines.silver_transform

# Gold only (aggregations)
python -m dwh.pipelines.gold_aggregates
```

### Selective Bronze Resources

```bash
# Only specific tables
DWH_BRONZE_RESOURCES=students,personas python -m dwh.pipelines.bronze_ingest
```

## Error Handling

### Invalid DuckDB File Recovery

If the DuckDB file becomes corrupted, the pipeline automatically:

1. Detects the invalid file
2. Renames it with timestamp suffix (`.invalid.{timestamp}.duckdb`)
3. Creates a fresh database file
4. Continues processing

### Incremental Cursor Coercion

Different source databases may return dates in different formats (DATE vs TIMESTAMPTZ). The pipeline automatically coerces cursor values to ensure compatibility.

### Fallback Queries

For optional or schema-variant sources, fallback SQL queries can be defined to handle missing tables or columns gracefully.

## Related Documentation

- [Bronze Layer Catalog](./BRONZE_CATALOG.md) - Source table definitions
- [Silver Layer Catalog](./SILVER_CATALOG.md) - Dimensional model
- [Gold Layer Catalog](./GOLD_CATALOG.md) - Business aggregations
- [Data Lineage](./DATA_LINEAGE.md) - Source-to-target mappings
