# Gold Layer Catalog

## Overview

The Gold layer provides business-ready aggregations and ML-specific features. It consists of two main categories:

1. **Data Marts (`mart_*`)** - Reusable business aggregations for BI, reporting, and general analytics
2. **TFT Feature Store (`gold_tft_*`)** - Specialized features for the Temporal Fusion Transformer dropout prediction model

## Architecture

```
                         SILVER LAYER
                              │
              ┌───────────────┴───────────────┐
              │                               │
              ▼                               ▼
    ┌─────────────────────────┐    ┌─────────────────────────┐
    │      DATA MARTS         │    │    TFT FEATURE STORE    │
    │   (Reusable / BI)       │    │    (ML-Specific)        │
    ├─────────────────────────┤    ├─────────────────────────┤
    │ mart_student_academic   │    │ gold_tft_static_features│
    │ mart_student_engagement │───▶│ gold_tft_temporal_      │
    │ mart_student_risk       │    │   features              │
    │ mart_cohort_analysis    │    │ gold_tft_known_future   │
    └─────────────────────────┘    │ gold_tft_training_      │
                                   │   dataset               │
                                   └─────────────────────────┘
                                              │
                                              ▼
                                   ┌─────────────────────────┐
                                   │    TFT MODEL TRAINING   │
                                   │       (PyTorch)         │
                                   └─────────────────────────┘
```

---

## Data Marts

### `gold.mart_student_academic_summary`

**File**: `sql/gold/01_mart_student_academic_summary.sql`  
**Grain**: One row per student per academic year  
**Purpose**: Aggregated academic performance metrics for BI and ML features

| Column                      | Type    | Description               |
| --------------------------- | ------- | ------------------------- |
| **Identifiers**             |         |                           |
| `alumno_id`                 | INTEGER | Student ID                |
| `anio_academico`            | INTEGER | Academic year             |
| **Course Counts**           |         |                           |
| `total_evaluaciones`        | INTEGER | Total evaluations in year |
| `materias_cursadas`         | INTEGER | Distinct courses taken    |
| **Grade Statistics**        |         |                           |
| `promedio_notas`            | DOUBLE  | Average grade             |
| `nota_minima`               | DOUBLE  | Minimum grade             |
| `nota_maxima`               | DOUBLE  | Maximum grade             |
| `desviacion_notas`          | DOUBLE  | Grade standard deviation  |
| **Pass/Fail Counts**        |         |                           |
| `materias_aprobadas`        | INTEGER | Courses passed            |
| `materias_reprobadas`       | INTEGER | Courses failed            |
| `materias_ausente`          | INTEGER | Courses absent            |
| **Rates**                   |         |                           |
| `tasa_aprobacion`           | DOUBLE  | Approval rate (0-1)       |
| `tasa_reprobacion`          | DOUBLE  | Failure rate (0-1)        |
| `tasa_ausentismo`           | DOUBLE  | Absenteeism rate (0-1)    |
| **Cumulative Metrics**      |         |                           |
| `total_evaluaciones_acum`   | INTEGER | Cumulative evaluations    |
| `materias_aprobadas_acum`   | INTEGER | Cumulative approved       |
| `materias_reprobadas_acum`  | INTEGER | Cumulative failed         |
| `promedio_historico`        | DOUBLE  | Historical average grade  |
| `tasa_aprobacion_historica` | DOUBLE  | Historical approval rate  |
| **Year-over-Year Changes**  |         |                           |
| `variacion_promedio`        | DOUBLE  | YoY grade change          |
| `variacion_tasa_aprobacion` | DOUBLE  | YoY approval rate change  |

**Business Logic**:

- Cumulative metrics use window functions with `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`
- Variations calculated using `LAG()` for trend detection
- Null grades are excluded from calculations

---

### `gold.mart_student_engagement`

**File**: `sql/gold/02_mart_student_engagement.sql`  
**Grain**: One row per student per academic year  
**Purpose**: Engagement and behavior metrics for student success tracking

| Column                        | Type      | Description                            |
| ----------------------------- | --------- | -------------------------------------- |
| **Identifiers**               |           |                                        |
| `alumno_id`                   | INTEGER   | Student ID                             |
| `anio_academico`              | INTEGER   | Academic year                          |
| **Attendance Features**       |           |                                        |
| `promedio_asistencia`         | DOUBLE    | Average attendance %                   |
| `total_inasistencias`         | INTEGER   | Total absences                         |
| `periodos_cumple_asistencia`  | INTEGER   | Periods meeting attendance requirement |
| `periodos_riesgo_asistencia`  | INTEGER   | Periods with attendance risk           |
| **Re-enrollment Features**    |           |                                        |
| `reinscripciones_anio`        | INTEGER   | Re-enrollments in year                 |
| `primera_reinscripcion`       | TIMESTAMP | First re-enrollment date               |
| `ultima_reinscripcion`        | TIMESTAMP | Last re-enrollment date                |
| **Exam Engagement**           |           |                                        |
| `examenes_inscriptos`         | INTEGER   | Exam enrollments                       |
| `materias_examen`             | INTEGER   | Distinct courses with exams            |
| **Overall Enrollment**        |           |                                        |
| `total_inscripciones_cursada` | INTEGER   | Total course enrollments               |
| `total_materias_inscriptas`   | INTEGER   | Distinct courses enrolled              |
| **Composite Score**           |           |                                        |
| `engagement_score`            | DOUBLE    | Weighted engagement score              |

**Engagement Score Formula**:

```sql
(promedio_asistencia * 0.4) + (reinscripciones_anio * 20) + (examenes_inscriptos * 5)
```

---

### `gold.mart_student_risk_features`

**File**: `sql/gold/03_mart_student_risk_features.sql`  
**Grain**: One row per student per academic year  
**Purpose**: Combined feature table for ML dropout prediction with risk indicators

| Column                       | Type    | Description                        |
| ---------------------------- | ------- | ---------------------------------- |
| **Identifiers**              |         |                                    |
| `alumno_id`                  | INTEGER | Student ID                         |
| `persona_id`                 | INTEGER | Person ID                          |
| `anio_academico`             | INTEGER | Academic year                      |
| **Student Characteristics**  |         |                                    |
| `propuesta_id`               | INTEGER | Program ID                         |
| `modalidad`                  | TEXT    | Study modality                     |
| `es_regular`                 | BOOLEAN | Regularity status                  |
| `anio_ingreso`               | INTEGER | Enrollment year                    |
| `antiguedad_anios`           | INTEGER | Years enrolled                     |
| `tipo_ingreso`               | TEXT    | Admission type                     |
| **Faculty**                  |         |                                    |
| `facultad_id`                | INTEGER | Faculty ID                         |
| `facultad_nombre`            | TEXT    | Faculty name                       |
| **Demographics**             |         |                                    |
| `sexo`                       | TEXT    | Gender                             |
| `edad_actual`                | INTEGER | Current age                        |
| `nacionalidad_desc`          | TEXT    | Nationality                        |
| **Socioeconomic**            |         |                                    |
| `estado_civil`               | INTEGER | Marital status                     |
| `cantidad_hijos`             | INTEGER | Number of children                 |
| `trabajo_existe`             | BOOLEAN | Currently employed                 |
| `trabajo_hora_sem`           | INTEGER | Weekly work hours                  |
| `beca`                       | BOOLEAN | Has scholarship                    |
| `costeos_estudios_*`         | BOOLEAN | Funding sources                    |
| `tecnologia_int_casa`        | BOOLEAN | Internet at home                   |
| `tecnologia_pc_casa`         | BOOLEAN | Computer at home                   |
| `nivel_estudio_previo`       | INTEGER | Previous education                 |
| `disc_*`                     | BOOLEAN | Disability flags                   |
| **Academic Performance**     |         |                                    |
| `materias_cursadas`          | INTEGER | Courses taken                      |
| `promedio_notas`             | DOUBLE  | Average grade                      |
| `nota_minima`                | DOUBLE  | Minimum grade                      |
| `desviacion_notas`           | DOUBLE  | Grade variance                     |
| `materias_aprobadas`         | INTEGER | Courses passed                     |
| `materias_reprobadas`        | INTEGER | Courses failed                     |
| `tasa_aprobacion`            | DOUBLE  | Approval rate                      |
| `tasa_reprobacion`           | DOUBLE  | Failure rate                       |
| `tasa_ausentismo`            | DOUBLE  | Absenteeism rate                   |
| `promedio_historico`         | DOUBLE  | Historical average                 |
| `tasa_aprobacion_historica`  | DOUBLE  | Historical approval rate           |
| `variacion_promedio`         | DOUBLE  | YoY grade change                   |
| `variacion_tasa_aprobacion`  | DOUBLE  | YoY approval change                |
| **Engagement**               |         |                                    |
| `promedio_asistencia`        | DOUBLE  | Average attendance                 |
| `total_inasistencias`        | INTEGER | Total absences                     |
| `periodos_riesgo_asistencia` | INTEGER | At-risk periods                    |
| `reinscripciones_anio`       | INTEGER | Re-enrollments                     |
| `examenes_inscriptos`        | INTEGER | Exam enrollments                   |
| `engagement_score`           | DOUBLE  | Engagement score                   |
| **Status Instability**       |         |                                    |
| `total_cambios_estado`       | INTEGER | Status changes                     |
| **Risk Indicators**          |         |                                    |
| `riesgo_academico`           | INTEGER | Academic risk (1/0)                |
| `riesgo_asistencia`          | INTEGER | Attendance risk (1/0)              |
| `riesgo_no_reinscripcion`    | INTEGER | No re-enrollment risk (1/0)        |
| `riesgo_trabajo_excesivo`    | INTEGER | Overwork risk (1/0)                |
| `risk_score_heuristic`       | INTEGER | Composite risk score               |
| **Target Variable**          |         |                                    |
| `dropout_label`              | INTEGER | **TARGET** (1=dropout, 0=retained) |
| `fecha_dropout`              | DATE    | Dropout date                       |

**Risk Indicator Thresholds**:

| Indicator                 | Condition                          | Weight |
| ------------------------- | ---------------------------------- | ------ |
| `riesgo_academico`        | `tasa_aprobacion < 0.5`            | 2      |
| `riesgo_asistencia`       | `promedio_asistencia < 60`         | 2      |
| `riesgo_no_reinscripcion` | `reinscripciones_anio = 0`         | 3      |
| `riesgo_trabajo_excesivo` | `trabajo_hora_sem > 30`            | 1      |
| Declining performance     | `variacion_tasa_aprobacion < -0.2` | 2      |
| Status instability        | `total_cambios_estado > 2`         | 1      |

**Maximum Risk Score**: 11 (sum of all weights)

---

### `gold.mart_cohort_analysis`

**File**: `sql/gold/04_mart_cohort_analysis.sql`  
**Grain**: One row per cohort-program-faculty combination  
**Purpose**: Cohort-level aggregations for trend analysis and model validation

| Column                         | Type    | Description                   |
| ------------------------------ | ------- | ----------------------------- |
| **Cohort Dimensions**          |         |                               |
| `cohorte`                      | INTEGER | Cohort year (enrollment year) |
| `propuesta_id`                 | INTEGER | Program ID                    |
| `propuesta_nombre`             | TEXT    | Program name                  |
| `facultad_id`                  | INTEGER | Faculty ID                    |
| `facultad_nombre`              | TEXT    | Faculty name                  |
| `sede_provincia`               | TEXT    | Province                      |
| **Size Metrics**               |         |                               |
| `total_estudiantes`            | INTEGER | Cohort size                   |
| **Dropout Metrics**            |         |                               |
| `total_desertores`             | INTEGER | Dropout count                 |
| `tasa_desercion_pct`           | DOUBLE  | Dropout rate (%)              |
| **Retention Metrics**          |         |                               |
| `total_retenidos`              | INTEGER | Retained count                |
| `tasa_retencion_pct`           | DOUBLE  | Retention rate (%)            |
| **Time-to-Dropout**            |         |                               |
| `promedio_anios_hasta_dropout` | DOUBLE  | Average years to dropout      |
| `min_anios_hasta_dropout`      | INTEGER | Minimum years to dropout      |
| `max_anios_hasta_dropout`      | INTEGER | Maximum years to dropout      |
| **Academic Performance**       |         |                               |
| `promedio_notas_cohorte`       | DOUBLE  | Cohort average grade          |
| `tasa_aprobacion_cohorte_pct`  | DOUBLE  | Cohort approval rate (%)      |

**Use Cases**:

- Temporal cross-validation (train/validation split by cohorts)
- Institutional reporting and benchmarking
- Program-level risk assessment
- Trend analysis across cohorts

---

## TFT Feature Store

The TFT (Temporal Fusion Transformer) Feature Store provides specialized features organized according to the TFT model architecture requirements.

### TFT Model Feature Categories

| Category                  | Description                               | Changes Over Time | Table                        |
| ------------------------- | ----------------------------------------- | ----------------- | ---------------------------- |
| **Static Covariates**     | Student characteristics that don't change | No                | `gold_tft_static_features`   |
| **Time-Varying Observed** | Historical features (past only)           | Yes               | `gold_tft_temporal_features` |
| **Known Future Inputs**   | Calendar/institutional features           | Yes (known ahead) | `gold_tft_known_future`      |
| **Target**                | Dropout label                             | Yes               | `gold_tft_training_dataset`  |

---

### `gold.gold_tft_static_features`

**File**: `sql/gold/10_gold_tft_static_features.sql`  
**Grain**: One row per student (unchanging)  
**Purpose**: Static covariates that don't change over time for each student

| Category                    | Columns                                                                                                                                                     |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Identifiers**             | `alumno_id`, `persona_id`                                                                                                                                   |
| **Student Characteristics** | `propuesta_id`, `propuesta_nombre`, `plan_version_id`, `ubicacion_id`, `modalidad`, `tipo_ingreso`, `anio_ingreso`, `fecha_ingreso`                         |
| **Demographics**            | `sexo`, `fecha_nacimiento`, `nacionalidad`, `nacionalidad_desc`, `localidad_nacimiento`, `localidad_nacimiento_desc`                                        |
| **Institutional Location**  | `sede_nombre`, `sede_localidad`, `sede_departamento`, `sede_provincia`, `sede_codigo_postal`                                                                |
| **Socioeconomic**           | `fecha_censo`, `estado_civil`, `union_pareja`, `cantidad_hijos`, `vive_con`, `situacion_padre`, `situacion_madre`, `cobertura_salud`, `tipo_vivienda`       |
| **Residence**               | `residencia_localidad`, `residencia_departamento`, `residencia_codigo_postal`                                                                               |
| **Origin**                  | `origen_localidad`, `origen_departamento`, `origen_codigo_postal`                                                                                           |
| **Employment**              | `trabajo_existe`, `trabajo_hora_sem`, `beca`                                                                                                                |
| **Study Financing**         | `costeos_estudios_familiar`, `costeos_estudios_plan_social`, `costeos_estudios_trabajo`, `costeos_estudios_beca`, `costeos_estudios_otro`                   |
| **Technology Access**       | `tecnologia_int_casa`, `tecnologia_pc_casa`, `tecnologia_int_movil`                                                                                         |
| **Disabilities**            | `disc_auditiva`, `disc_visual`, `disc_motora`, `disc_otra`                                                                                                  |
| **Prior Education**         | `nivel_estudio_previo`, `nivel_estudio_previo_desc`, `colegio_secundario_id`, `colegio_secundario_desc`, `institucion_previa_id`, `institucion_previa_desc` |
| **Activities**              | `deportes`                                                                                                                                                  |

**Sources**: `dim_student` + `dim_persona` + `dim_ubicacion` + `dim_census`

---

### `gold.gold_tft_temporal_features`

**File**: `sql/gold/11_gold_tft_temporal_features.sql`  
**Grain**: One row per student per academic year  
**Purpose**: Time-varying observed inputs (historical features that change over time)

| Category                 | Columns                                                                                                                                                                                                                                                                                                                       |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Time Indices**         | `time_step`, `anios_desde_ingreso`                                                                                                                                                                                                                                                                                            |
| **Academic Performance** | `total_evaluaciones`, `materias_cursadas`, `cursadas_intentadas`, `examenes_intentados`, `promedio_notas`, `nota_minima`, `nota_maxima`, `desviacion_notas`, `mediana_notas`, `materias_aprobadas`, `materias_reprobadas`, `materias_ausente`, `tasa_aprobacion`, `tasa_reprobacion`, `tasa_ausentismo`, `creditos_obtenidos` |
| **Attendance**           | `promedio_asistencia`, `total_inasistencias`, `periodos_cumple_asistencia`, `periodos_riesgo_asistencia`                                                                                                                                                                                                                      |
| **Enrollment Behavior**  | `inscripciones_cursada`, `materias_inscriptas`, `examenes_inscriptos`, `materias_examen_inscriptas`                                                                                                                                                                                                                           |
| **Re-inscription**       | `tuvo_reinscripcion`, `reinscripciones`, `primera_reinscripcion`, `ultima_reinscripcion`                                                                                                                                                                                                                                      |
| **Status Stability**     | `cambios_estado_anio`                                                                                                                                                                                                                                                                                                         |
| **Cumulative Features**  | `materias_aprobadas_acum`, `materias_reprobadas_acum`, `creditos_acum`, `promedio_historico`, `tasa_aprobacion_historica`                                                                                                                                                                                                     |
| **Lag Features**         | `promedio_notas_anterior`, `tasa_aprobacion_anterior`, `tuvo_reinscripcion_anterior`                                                                                                                                                                                                                                          |
| **Trend Features**       | `variacion_promedio`, `variacion_tasa_aprobacion`, `variacion_materias`                                                                                                                                                                                                                                                       |
| **Target**               | `dropout_flag`, `dropout_next_year`, `fecha_dropout`                                                                                                                                                                                                                                                                          |

**Key Derived Features**:

- `time_step`: Sequence position for each student
- `anios_desde_ingreso`: Years since enrollment
- `*_acum`: Cumulative features using window functions
- `*_anterior`: Lag features using `LAG()` function
- `variacion_*`: Year-over-year changes
- `dropout_next_year`: Forward-looking target for prediction

---

### `gold.gold_tft_known_future`

**File**: `sql/gold/12_gold_tft_known_future.sql`  
**Grain**: One row per academic year  
**Purpose**: Features that are known in advance (calendar, institutional)

| Column             | Type    | Description          |
| ------------------ | ------- | -------------------- |
| `anio_academico`   | INTEGER | Academic year        |
| `fecha_inicio`     | DATE    | Period start date    |
| `fecha_fin`        | DATE    | Period end date      |
| `periodo_label`    | TEXT    | Display label        |
| `anio_relativo`    | INTEGER | Relative position    |
| `mes_inicio`       | INTEGER | Start month          |
| `trimestre_inicio` | INTEGER | Start quarter        |
| `time_index`       | INTEGER | Time sequence index  |
| `post_pandemia`    | INTEGER | Post-2020 flag (1/0) |

**Use Case**: These features help the model understand temporal context and can capture institutional changes (e.g., COVID-19 impact starting 2020).

---

### `gold.gold_tft_training_dataset`

**File**: `sql/gold/13_gold_tft_training_dataset.sql`  
**Grain**: One row per student per academic year  
**Purpose**: Final training dataset joining all feature categories for TFT model

**Structure**:

```
┌─────────────────────────────────────────────────────────────────┐
│                    TRAINING DATASET RECORD                       │
├─────────────────────────────────────────────────────────────────┤
│ IDENTIFIERS                                                      │
│   alumno_id, persona_id, anio_academico, time_step              │
├─────────────────────────────────────────────────────────────────┤
│ STATIC COVARIATES (from gold_tft_static_features)               │
│   Demographics, Socioeconomic, Prior Education, Location...     │
├─────────────────────────────────────────────────────────────────┤
│ KNOWN FUTURE INPUTS (from gold_tft_known_future)                │
│   mes_inicio, trimestre_inicio, post_pandemia                   │
├─────────────────────────────────────────────────────────────────┤
│ TIME-VARYING OBSERVED (from gold_tft_temporal_features)         │
│   Academic performance, Attendance, Enrollment, Trends...       │
├─────────────────────────────────────────────────────────────────┤
│ SEQUENCE METADATA                                                │
│   sequence_length, is_last_observation                          │
├─────────────────────────────────────────────────────────────────┤
│ TARGET VARIABLES                                                 │
│   dropout_flag, dropout_next_year, fecha_dropout                │
└─────────────────────────────────────────────────────────────────┘
```

**Sequence Metadata**:

- `sequence_length`: Total time steps for each student
- `is_last_observation`: Flag for last record in sequence (useful for inference)

**Join Logic**:

```sql
FROM gold.gold_tft_temporal_features tf
LEFT JOIN gold.gold_tft_static_features sf ON tf.alumno_id = sf.alumno_id
LEFT JOIN gold.gold_tft_known_future kf ON tf.anio_academico = kf.anio_academico
```

---

## Execution Order

Gold layer SQL files are executed in alphabetical order:

```
01_mart_student_academic_summary.sql    # Reads silver tables
02_mart_student_engagement.sql          # Reads silver tables
03_mart_student_risk_features.sql       # Depends on 01, 02 marts
04_mart_cohort_analysis.sql             # Reads silver tables
10_gold_tft_static_features.sql         # Reads silver dimensions
11_gold_tft_temporal_features.sql       # Reads silver facts
12_gold_tft_known_future.sql            # Reads silver.dim_periodo
13_gold_tft_training_dataset.sql        # Depends on 10, 11, 12
```

---

## Feature Engineering Patterns

### Cumulative Features

```sql
SUM(materias_aprobadas) OVER (
    PARTITION BY alumno_id
    ORDER BY anio_academico
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS materias_aprobadas_acum
```

### Lag Features (Previous Year)

```sql
LAG(promedio_notas) OVER (
    PARTITION BY alumno_id
    ORDER BY anio_academico
) AS promedio_notas_anterior
```

### Year-over-Year Variation

```sql
promedio_notas - LAG(promedio_notas) OVER (
    PARTITION BY alumno_id
    ORDER BY anio_academico
) AS variacion_promedio
```

### Forward Target (Next Year Prediction)

```sql
LEAD(dropout_flag) OVER (
    PARTITION BY alumno_id
    ORDER BY anio_academico
) AS dropout_next_year
```

---

## Usage Notes

### For BI/Dashboards

Use the `mart_*` tables for general analytics and reporting:

- `mart_student_academic_summary` - Student performance dashboards
- `mart_student_engagement` - Engagement tracking
- `mart_student_risk_features` - Risk monitoring with pre-calculated indicators
- `mart_cohort_analysis` - Institutional reporting and trends

### For ML Model Training

Use the TFT Feature Store tables:

1. `gold_tft_training_dataset` - Primary training data
2. Individual feature tables for feature selection/analysis

### For Inference/Prediction

Use `gold_tft_training_dataset` filtered by `is_last_observation = 1` to get current state of active students for prediction.
