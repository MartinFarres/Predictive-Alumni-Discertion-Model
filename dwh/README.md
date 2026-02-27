# Data Warehouse (DWH)

## Descripción

Pipeline de Data Warehouse local implementado con dlt y DuckDB, siguiendo la arquitectura Medallion (Bronze, Silver, Gold). Diseñado para soportar el modelo de predicción de deserción estudiantil basado en Temporal Fusion Transformers (TFT).

## 📚 Documentación

| Documento                                 | Descripción                                                  |
| ----------------------------------------- | ------------------------------------------------------------ |
| [Arquitectura](docs/ARCHITECTURE.md)      | Visión general del sistema, diagrama de flujo, configuración |
| [Catálogo Bronze](docs/BRONZE_CATALOG.md) | Tablas de datos crudos, patrones de extracción               |
| [Catálogo Silver](docs/SILVER_CATALOG.md) | Modelo dimensional (dimensiones y hechos)                    |
| [Catálogo Gold](docs/GOLD_CATALOG.md)     | Data Marts y Feature Store para ML                           |
| [Lineage de Datos](docs/DATA_LINEAGE.md)  | Trazabilidad fuente → destino                                |

## Stack Tecnológico

| Componente       | Tecnología            | Versión |
| ---------------- | --------------------- | ------- |
| Ingestión        | dlt (data load tool)  | ≥1.6.0  |
| Almacenamiento   | DuckDB                | ≥1.0.0  |
| Transformaciones | SQL                   | -       |
| Conectividad     | SQLAlchemy + psycopg2 | ≥2.0    |

## Arquitectura Medallion

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              BRONZE                                      │
│                         Datos crudos de origen                          │
│   Tablas: academic, students, personas, census, dropout, etc.           │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                              SILVER                                      │
│                    Data Warehouse (dimensiones + hechos)                │
│                         Single Source of Truth                          │
│   Dimensiones: dim_student, dim_persona, dim_census, dim_elemento       │
│   Hechos: fact_academic_performance, fact_dropout, fact_attendance      │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
              ┌─────────────────────┼─────────────────────┐
              ▼                     ▼                     ▼
┌─────────────────────┐  ┌─────────────────┐  ┌─────────────────────┐
│     GOLD - TFT      │  │   GOLD - Marts  │  │   GOLD - Otros      │
│   (Feature Store)   │  │      (BI)       │  │     (Extensible)    │
└─────────────────────┘  └─────────────────┘  └─────────────────────┘
```

### Capas

| Capa   | Descripción                                 | Ubicación       |
| ------ | ------------------------------------------- | --------------- |
| Bronze | Copia fiel de datos origen                  | Schema `bronze` |
| Silver | Dimensiones y hechos conformados (DWH core) | Schema `silver` |
| Gold   | Data Marts y Feature Stores específicos     | Schema `gold`   |

### Convención de Nombres - Gold Layer

| Prefijo      | Propósito                            | Reutilizable |
| ------------ | ------------------------------------ | ------------ |
| `mart_*`     | Data marts genéricos (BI, reportes)  | Sí           |
| `gold_tft_*` | Features específicas para modelo TFT | No           |

## Estructura de Directorios

```
dwh/
├── data/
│   └── warehouse.duckdb
├── pipelines/
│   ├── bronze_ingest.py
│   ├── silver_transform.py
│   └── gold_aggregates.py
├── sources/
│   └── sql_sources.py
├── sql/
│   ├── bronze/
│   ├── silver/
│   │   ├── 01_dim_*.sql
│   │   └── 20_fact_*.sql
│   └── gold/
│       ├── 01_mart_*.sql
│       └── 10_gold_tft_*.sql
├── config.py
├── main.py
└── requirements.txt
```

### Convención de Archivos SQL

| Rango | Tipo         | Ejemplo                           |
| ----- | ------------ | --------------------------------- |
| 01-09 | Dimensiones  | `01_dim_fecha.sql`                |
| 10-19 | Features TFT | `10_gold_tft_static_features.sql` |
| 20-29 | Hechos       | `20_fact_course_enrollment.sql`   |

## Configuración

1. Copiar `config.example.py` a `config.py`
2. Configurar `SOURCE_DATABASES` con las credenciales de conexión

```python
SOURCE_DATABASES = [
    {
        "name": "guarani_prod",
        "conn_string": "postgresql://user:pass@host:5432/db"
    },
]
```

> **Nota**: Para configuración avanzada y variables de entorno, ver [Arquitectura](docs/ARCHITECTURE.md#configuration).

## Ejecución

### Pipeline Completo

```bash
python -m dwh.main
```

### Ejecución por Etapas

```bash
python -m dwh.pipelines.bronze_ingest
python -m dwh.pipelines.silver_transform
python -m dwh.pipelines.gold_aggregates
```

### Ejecución Selectiva (Bronze)

```bash
# Solo tablas específicas
DWH_BRONZE_RESOURCES=students,personas python -m dwh.pipelines.bronze_ingest
```

## Dependencias

```
dlt>=1.6.0
duckdb>=1.0.0
sqlalchemy>=2.0.0
psycopg2-binary>=2.9.0
```

Ver `requirements.txt` para la lista completa.

## Próximos Pasos

- [ ] Migrar credenciales a `.dlt/secrets.toml`
- [ ] Agregar tests de calidad de datos
- [ ] Implementar scheduling con Airflow/Prefect
