# Dashboard BI - Análisis de Retención Estudiantil

## Descripción

Panel de control ejecutivo para el análisis de retención y deserción estudiantil. Diseñado para la toma de decisiones a nivel directivo, presenta indicadores clave de rendimiento (KPIs) y visualizaciones sobre el comportamiento estudiantil.

## Funcionalidades

| Módulo                | Descripción                                                           |
| --------------------- | --------------------------------------------------------------------- |
| Resumen Ejecutivo     | KPIs principales: tasa de retención, deserción, estudiantes en riesgo |
| Análisis por Cohorte  | Evolución temporal de métricas por año de ingreso                     |
| Análisis por Carrera  | Comparativo de rendimiento entre programas académicos                 |
| Indicadores de Riesgo | Distribución de estudiantes según nivel de riesgo                     |
| Rendimiento Académico | Métricas de aprobación, calificaciones y asistencia                   |

## Stack Tecnológico

| Componente    | Tecnología        |
| ------------- | ----------------- |
| Framework     | Streamlit         |
| Visualización | Plotly            |
| Base de Datos | DuckDB            |
| Estilos       | CSS personalizado |

## Requisitos

- Python 3.10+
- Acceso al archivo `warehouse.duckdb` generado por el pipeline DWH

## Instalación

```bash
cd dashboard
pip install -r requirements.txt
```

## Configuración

El dashboard busca automáticamente el archivo de base de datos en:

- `../dwh/data/warehouse.duckdb`

Para especificar una ubicación diferente, establecer la variable de entorno:

```bash
export DWH_DATABASE_PATH=/ruta/al/warehouse.duckdb
```

## Ejecución

```bash
streamlit run app.py
```

El dashboard estará disponible en `http://localhost:8501`

## Estructura

```
dashboard/
├── app.py              # Aplicación principal
├── config.py           # Configuración y conexión a BD
├── data_access.py      # Capa de acceso a datos
├── components/         # Componentes de visualización
│   ├── __init__.py
│   ├── kpis.py
│   ├── charts.py
│   └── filters.py
├── assets/
│   └── styles.css
├── requirements.txt
└── README.md
```

## Métricas Disponibles

### Indicadores de Retención

| Métrica                         | Descripción                                     |
| ------------------------------- | ----------------------------------------------- |
| Tasa de Retención               | Porcentaje de estudiantes que continúan activos |
| Tasa de Deserción               | Porcentaje de estudiantes que abandonaron       |
| Tiempo Promedio hasta Deserción | Años transcurridos desde ingreso hasta abandono |

### Indicadores Académicos

| Métrica                    | Descripción                        |
| -------------------------- | ---------------------------------- |
| Promedio de Calificaciones | Media de notas por período/carrera |
| Tasa de Aprobación         | Porcentaje de materias aprobadas   |
| Promedio de Asistencia     | Porcentaje de asistencia promedio  |

### Indicadores de Riesgo

| Métrica                     | Descripción                                   |
| --------------------------- | --------------------------------------------- |
| Estudiantes en Riesgo Alto  | Cantidad con probabilidad >70% de deserción   |
| Estudiantes en Riesgo Medio | Cantidad con probabilidad 40-70% de deserción |
| Estudiantes en Riesgo Bajo  | Cantidad con probabilidad <40% de deserción   |

## Fuente de Datos

Los datos provienen de la capa Gold del Data Warehouse:

| Tabla                                | Uso                              |
| ------------------------------------ | -------------------------------- |
| `gold.mart_cohort_analysis`          | Análisis por cohorte y carrera   |
| `gold.mart_student_risk_features`    | Indicadores de riesgo individual |
| `gold.mart_student_academic_summary` | Métricas académicas              |
| `gold.mart_student_engagement`       | Métricas de engagement           |
