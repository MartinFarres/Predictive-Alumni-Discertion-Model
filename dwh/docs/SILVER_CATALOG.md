# Silver Layer Catalog

## Overview

The Silver layer implements a **Star Schema** dimensional model, providing a cleaned, conformed, and business-ready data structure. This layer serves as the **Single Source of Truth (SSOT)** for all downstream analytics and ML feature engineering.

## Schema Design

```
                         ┌─────────────────┐
                         │   dim_fecha     │
                         │  (Date Spine)   │
                         └────────┬────────┘
                                  │
┌──────────────┐         ┌────────┴────────┐         ┌──────────────────┐
│ dim_student  │─────────│    FACT TABLES  │─────────│   dim_elemento   │
│   (Hub)      │         │                 │         │   (Courses)      │
└──────┬───────┘         └────────┬────────┘         └──────────────────┘
       │                          │
┌──────┴───────┐         ┌────────┴────────┐         ┌──────────────────┐
│ dim_persona  │         │  dim_propuesta  │         │   dim_instancia  │
│(Demographics)│         │   (Programs)    │         │  (Exam Types)    │
└──────────────┘         └─────────────────┘         └──────────────────┘
       │
┌──────┴───────┐         ┌─────────────────┐         ┌──────────────────┐
│ dim_census   │         │  dim_facultad   │         │  dim_plan_version│
│(Socioeconomic)         │   (Faculty)     │         │   (Curriculum)   │
└──────────────┘         └─────────────────┘         └──────────────────┘
```

## Transformation Pattern

All Silver tables are created using `CREATE OR REPLACE TABLE`, meaning they are fully refreshed on each pipeline run. This ensures data consistency and simplifies the transformation logic.

---

## Dimension Tables

### `silver.dim_fecha` (Date Dimension)

**File**: `sql/silver/01_dim_fecha.sql`  
**Purpose**: Standard calendar dimension for time-based analysis.

| Column              | Type    | Description                    |
| ------------------- | ------- | ------------------------------ |
| `fecha`             | DATE    | Date (primary key)             |
| `anio`              | INTEGER | Calendar year                  |
| `mes`               | INTEGER | Month (1-12)                   |
| `dia`               | INTEGER | Day of month                   |
| `trimestre`         | INTEGER | Quarter (1-4)                  |
| `semana`            | INTEGER | Week of year                   |
| `dia_semana`        | INTEGER | Day of week (0=Sunday)         |
| `dia_nombre`        | TEXT    | Day name (Spanish locale)      |
| `mes_nombre`        | TEXT    | Month name                     |
| `anio_academico`    | INTEGER | Academic year (March-February) |
| `cuatrimestre`      | INTEGER | Academic semester (1 or 2)     |
| `es_fin_semana`     | BOOLEAN | Weekend flag                   |
| `es_primer_dia_mes` | BOOLEAN | First day of month flag        |
| `es_ultimo_dia_mes` | BOOLEAN | Last day of month flag         |

**Range**: 2000-01-01 to 2030-12-31

**Notes**:

- Academic year follows Argentine calendar (March → February)
- Cuatrimestre 1: March-July, Cuatrimestre 2: August-December
- January-February belongs to previous year's 2nd semester

---

### `silver.dim_periodo` (Academic Period Dimension)

**File**: `sql/silver/02_dim_periodo.sql`  
**Purpose**: Academic years extracted from transactional data.

| Column           | Type    | Description                       |
| ---------------- | ------- | --------------------------------- |
| `anio_academico` | INTEGER | Academic year (primary key)       |
| `fecha_inicio`   | DATE    | Period start (March 1)            |
| `fecha_fin`      | DATE    | Period end (February 28/29)       |
| `periodo_label`  | TEXT    | Display label (e.g., "2023-2024") |
| `anio_relativo`  | INTEGER | Relative position from first year |

**Source**: UNION of distinct `anio_academico` from `bronze.academic`, `bronze.reinscripciones`, `bronze.dropout`, `bronze.attendance`

---

### `silver.dim_propuesta` (Academic Program Dimension)

**File**: `sql/silver/03_dim_propuesta.sql`  
**Purpose**: Master catalog of academic programs/careers.

| Column             | Type    | Description              |
| ------------------ | ------- | ------------------------ |
| `propuesta_id`     | INTEGER | Program ID (primary key) |
| `propuesta_nombre` | TEXT    | Program name             |
| `propuesta_codigo` | TEXT    | Program code             |

**Source**: `bronze.students`

---

### `silver.dim_facultad` (Faculty Dimension)

**File**: `sql/silver/03b_dim_facultad.sql`  
**Purpose**: Faculty and university delegation information.

| Column               | Type    | Description                         |
| -------------------- | ------- | ----------------------------------- |
| `facultad_id`        | INTEGER | Faculty ID (surrogate key)          |
| `facultad_nombre`    | TEXT    | Faculty/institution name            |
| `universidad_nombre` | TEXT    | Parent university name              |
| `sede_provincia`     | TEXT    | Province location                   |
| `tipo_sede`          | TEXT    | Sede type (Sede Central/Delegación) |
| `ubicacion_sede`     | TEXT    | Location category                   |

**Derived Logic**:

- `tipo_sede`: Derived from institution name pattern matching
- `ubicacion_sede`: Maps to regional locations (San Rafael, Zona Este, etc.)

---

### `silver.dim_plan_version` (Curriculum Version Dimension)

**File**: `sql/silver/04_dim_plan_version.sql`  
**Purpose**: Different versions of study plans/curricula.

| Column                | Type    | Description                   |
| --------------------- | ------- | ----------------------------- |
| `plan_version_id`     | INTEGER | Plan version ID (primary key) |
| `plan_version_nombre` | TEXT    | Plan version name             |

**Source**: UNION of `bronze.students` and `bronze.course_inscriptions`

---

### `silver.dim_elemento` (Course/Subject Dimension)

**File**: `sql/silver/05_dim_elemento.sql`  
**Purpose**: Master catalog of academic courses.

| Column           | Type    | Description             |
| ---------------- | ------- | ----------------------- |
| `elemento_id`    | INTEGER | Course ID (primary key) |
| `materia_codigo` | TEXT    | Course code             |
| `materia_nombre` | TEXT    | Course name             |

**Source**: `bronze.elementos`

---

### `silver.dim_instancia` (Exam Instance Type Dimension)

**File**: `sql/silver/06_dim_instancia.sql`  
**Purpose**: Types of exam instances (regular, makeup, etc.).

| Column             | Type    | Description                    |
| ------------------ | ------- | ------------------------------ |
| `instancia_id`     | INTEGER | Instance type ID (primary key) |
| `instancia_nombre` | TEXT    | Instance type name             |

**Source**: `bronze.instancias`

---

### `silver.dim_ubicacion` (Campus/Location Dimension)

**File**: `sql/silver/07_dim_ubicacion.sql`  
**Purpose**: Physical locations where students attend.

| Column              | Type    | Description               |
| ------------------- | ------- | ------------------------- |
| `ubicacion_id`      | INTEGER | Location ID (primary key) |
| `see_nombre`        | TEXT    | Location name             |
| `see_calle`         | TEXT    | Street address            |
| `see_numero`        | TEXT    | Street number             |
| `see_codigo_postal` | TEXT    | Postal code               |
| `see_institucion`   | TEXT    | Institution name          |
| `see_institucion_p` | TEXT    | Parent institution        |
| `see_localidad`     | TEXT    | City                      |
| `see_dpto`          | TEXT    | Department/district       |
| `see_provincia`     | TEXT    | Province                  |

**Source**: `bronze.students`

---

### `silver.dim_persona` (Person Demographics Dimension)

**File**: `sql/silver/08_dim_persona.sql`  
**Purpose**: Demographic information about individuals.

| Column                      | Type    | Description              |
| --------------------------- | ------- | ------------------------ |
| `persona_id`                | INTEGER | Person ID (primary key)  |
| `fecha_nacimiento`          | DATE    | Birth date               |
| `edad_actual`               | INTEGER | Current age (calculated) |
| `sexo`                      | TEXT    | Gender (M/F)             |
| `localidad_nacimiento`      | INTEGER | Birth city ID            |
| `localidad_nacimiento_desc` | TEXT    | Birth city name          |
| `nacionalidad`              | INTEGER | Nationality ID           |
| `nacionalidad_desc`         | TEXT    | Nationality description  |

**Source**: `bronze.personas`

**Notes**: `edad_actual` is snapshot-based; for point-in-time age, join with `dim_fecha`

---

### `silver.dim_census` (Socioeconomic Dimension)

**File**: `sql/silver/09_dim_census.sql`  
**Purpose**: Socioeconomic and census data for risk prediction features.

| Column                              | Type    | Description                  |
| ----------------------------------- | ------- | ---------------------------- |
| `persona_id`                        | INTEGER | Person ID (primary key)      |
| `fecha_relevamiento`                | DATE    | Survey date                  |
| **Family & Status**                 |         |                              |
| `estado_civil`                      | INTEGER | Marital status code          |
| `estado_civil_desc`                 | TEXT    | Marital status description   |
| `union_pareja`                      | BOOLEAN | Has partner                  |
| `situacion_padre`                   | TEXT    | Father's situation           |
| `situacion_madre`                   | TEXT    | Mother's situation           |
| `cantidad_hijos`                    | INTEGER | Number of children           |
| `vive_con`                          | TEXT    | Living arrangement           |
| **Health**                          |         |                              |
| `cobertura_salud`                   | TEXT    | Health coverage type         |
| **Housing**                         |         |                              |
| `tipo_vivienda`                     | INTEGER | Housing type code            |
| `tipo_vivienda_desc`                | TEXT    | Housing type description     |
| **Academic Period Address**         |         |                              |
| `periodo_lectivo_localidad`         | INTEGER | City ID (academic period)    |
| `periodo_lectivo_localidad_desc`    | TEXT    | City name                    |
| `periodo_lectivo_departamento`      | INTEGER | Department ID                |
| `periodo_lectivo_departamento_desc` | TEXT    | Department name              |
| `periodo_lectivo_codigo_postal`     | TEXT    | Postal code                  |
| **Origin Address**                  |         |                              |
| `procedencia_localidad`             | INTEGER | Origin city ID               |
| `procedencia_localidad_desc`        | TEXT    | Origin city name             |
| `procedencia_departamento`          | INTEGER | Origin department ID         |
| `procedencia_departamento_desc`     | TEXT    | Origin department name       |
| `procedencia_codigo_postal`         | TEXT    | Origin postal code           |
| **Employment**                      |         |                              |
| `trabajo_existe`                    | BOOLEAN | Currently employed           |
| `trabajo_existe_desc`               | TEXT    | Employment description       |
| `trabajo_hora_sem`                  | INTEGER | Weekly work hours            |
| `beca`                              | BOOLEAN | Has scholarship              |
| **Study Financing**                 |         |                              |
| `costeos_estudios_familiar`         | BOOLEAN | Family-funded                |
| `costeos_estudios_plan_social`      | BOOLEAN | Social plan funded           |
| `costeos_estudios_trabajo`          | BOOLEAN | Self-funded (work)           |
| `costeos_estudios_beca`             | BOOLEAN | Scholarship-funded           |
| `costeos_estudios_otro`             | BOOLEAN | Other funding                |
| **Technology Access**               |         |                              |
| `tecnologia_int_casa`               | BOOLEAN | Internet at home             |
| `tecnologia_pc_casa`                | BOOLEAN | Computer at home             |
| `tecnologia_int_movil`              | BOOLEAN | Mobile internet              |
| **Activities**                      |         |                              |
| `deportes`                          | BOOLEAN | Practices sports             |
| **Disabilities**                    |         |                              |
| `disc_auditiva`                     | BOOLEAN | Hearing disability           |
| `disc_visual`                       | BOOLEAN | Visual disability            |
| `disc_motora`                       | BOOLEAN | Motor disability             |
| `disc_otra`                         | BOOLEAN | Other disability             |
| `disc_otra_descripcion`             | TEXT    | Other disability description |
| **Prior Education**                 |         |                              |
| `nivel_estudio_previo`              | INTEGER | Previous education level     |
| `nivel_estudio_previo_desc`         | TEXT    | Education level description  |
| `institucion_previa_id`             | INTEGER | Previous institution ID      |
| `institucion_previa_desc`           | TEXT    | Previous institution name    |
| `colegio_secundario_id`             | INTEGER | High school ID               |
| `colegio_secundario_desc`           | TEXT    | High school name             |

**Source**: `bronze.census`

**ML Importance**: This dimension contains critical risk factors for dropout prediction.

---

### `silver.dim_student` (Student Master Dimension)

**File**: `sql/silver/10_dim_student.sql`  
**Purpose**: Core student dimension linking all student-related information.

| Column               | Type    | Description                 |
| -------------------- | ------- | --------------------------- |
| `alumno_id`          | INTEGER | Student ID (primary key)    |
| `persona_id`         | INTEGER | FK to dim_persona           |
| **Academic Program** |         |                             |
| `propuesta_id`       | INTEGER | FK to dim_propuesta         |
| `propuesta_nombre`   | TEXT    | Program name (denormalized) |
| `plan_version_id`    | INTEGER | FK to dim_plan_version      |
| `plan_version`       | TEXT    | Plan version name           |
| **Faculty**          |         |                             |
| `facultad_id`        | INTEGER | FK to dim_facultad          |
| `facultad_nombre`    | TEXT    | Faculty name                |
| `universidad_nombre` | TEXT    | University name             |
| `tipo_sede`          | TEXT    | Sede type                   |
| `ubicacion_sede`     | TEXT    | Location category           |
| **Location**         |         |                             |
| `ubicacion_id`       | INTEGER | FK to dim_ubicacion         |
| `sede_provincia`     | TEXT    | Province                    |
| **Status**           |         |                             |
| `modalidad`          | TEXT    | Study modality              |
| `es_regular`         | BOOLEAN | Current regularity status   |
| **Enrollment**       |         |                             |
| `fecha_ingreso`      | DATE    | Enrollment date             |
| `tipo_ingreso`       | TEXT    | Admission type              |
| `anio_ingreso`       | INTEGER | Enrollment year             |
| `antiguedad_anios`   | INTEGER | Years since enrollment      |

**Source**: `bronze.students` + `silver.dim_facultad`

---

## Fact Tables

### `silver.fact_course_enrollment` (Course Inscriptions)

**File**: `sql/silver/20_fact_course_enrollment.sql`  
**Grain**: One row per student-course-period enrollment  
**Purpose**: Track course enrollment events.

| Column               | Type      | Description                |
| -------------------- | --------- | -------------------------- |
| `alumno_id`          | INTEGER   | FK to dim_student          |
| `elemento_id`        | INTEGER   | FK to dim_elemento         |
| `plan_version_id`    | INTEGER   | FK to dim_plan_version     |
| `inscripcion_id`     | INTEGER   | Enrollment ID              |
| `fecha_inscripcion`  | TIMESTAMP | Enrollment date            |
| `estado_inscripcion` | TEXT      | Enrollment status          |
| `periodo_lectivo`    | TEXT      | Academic period            |
| `catedra_cod`        | TEXT      | Course code (denormalized) |
| `catedra_nombre`     | TEXT      | Course name (denormalized) |
| `enrollment_count`   | INTEGER   | Count metric (always 1)    |

**Source**: `bronze.course_inscriptions`

---

### `silver.fact_academic_performance` (Academic Grades)

**File**: `sql/silver/21_fact_academic_performance.sql`  
**Grain**: One row per student-course-period evaluation  
**Purpose**: Track academic grades and performance.

| Column                  | Type    | Description             |
| ----------------------- | ------- | ----------------------- |
| `alumno_id`             | INTEGER | FK to dim_student       |
| `elemento_id`           | INTEGER | FK to dim_elemento      |
| `anio_academico`        | INTEGER | FK to dim_periodo       |
| `periodo_lectivo`       | INTEGER | Academic period         |
| `plan_version_id`       | INTEGER | FK to dim_plan_version  |
| `instancia_id`          | INTEGER | FK to dim_instancia     |
| `nota`                  | NUMERIC | Grade value             |
| `nota_descripcion`      | TEXT    | Grade description       |
| `resultado`             | TEXT    | Result code             |
| `resultado_descripcion` | TEXT    | Result description      |
| `fecha_evaluacion`      | DATE    | Evaluation date         |
| `tipo_evaluacion`       | TEXT    | Evaluation type         |
| `origen`                | TEXT    | Data origin             |
| `pct_asistencia`        | NUMERIC | Attendance percentage   |
| `creditos`              | INTEGER | Credits earned          |
| **Derived Flags**       |         |                         |
| `aprobado_flag`         | INTEGER | Approved (1/0)          |
| `reprobado_flag`        | INTEGER | Failed (1/0)            |
| `ausente_flag`          | INTEGER | Absent (1/0)            |
| `evaluation_count`      | INTEGER | Count metric (always 1) |

**Source**: `bronze.historia_academica`

**Result Codes**:

- `A`, `P`, `R` → Approved
- `D`, `L`, `U` → Failed
- `A` → Absent

---

### `silver.fact_exam_inscription` (Exam Inscriptions)

**File**: `sql/silver/22_fact_exam_inscription.sql`  
**Grain**: One row per student-exam-instance  
**Purpose**: Track exam enrollment events.

| Column                   | Type    | Description             |
| ------------------------ | ------- | ----------------------- |
| `alumno_id`              | INTEGER | FK to dim_student       |
| `elemento_id`            | INTEGER | FK to dim_elemento      |
| `instancia_id`           | INTEGER | FK to dim_instancia     |
| `plan_version_id`        | INTEGER | FK to dim_plan_version  |
| `inscripcion_id`         | INTEGER | Enrollment ID           |
| `fecha_mesa_examen`      | DATE    | Exam date               |
| `instancia_desc`         | TEXT    | Instance description    |
| `catedra_cod`            | TEXT    | Course code             |
| `catedra_nombre`         | TEXT    | Course name             |
| `exam_inscription_count` | INTEGER | Count metric (always 1) |

**Source**: `bronze.exam_inscriptions`

---

### `silver.fact_attendance` (Attendance Records)

**File**: `sql/silver/23_fact_attendance.sql`  
**Grain**: One row per student-year  
**Purpose**: Track attendance metrics.

| Column                   | Type    | Description              |
| ------------------------ | ------- | ------------------------ |
| `alumno_id`              | INTEGER | FK to dim_student        |
| `anio_academico`         | INTEGER | FK to dim_periodo        |
| `porc_asistencia`        | NUMERIC | Attendance percentage    |
| `total_inasistencias`    | INTEGER | Total absences           |
| **Derived Flags**        |         |                          |
| `cumple_asistencia_flag` | INTEGER | Meets requirement (≥75%) |
| `riesgo_asistencia_flag` | INTEGER | At risk (<50%)           |

**Source**: `bronze.attendance`

**Business Rules**:

- `cumple_asistencia_flag`: 1 if attendance ≥ 75%
- `riesgo_asistencia_flag`: 1 if attendance < 50%

---

### `silver.fact_reinscription` (Re-enrollment Events)

**File**: `sql/silver/24_fact_reinscription.sql`  
**Grain**: One row per student-year re-enrollment  
**Purpose**: Track annual re-enrollment.

| Column                | Type      | Description             |
| --------------------- | --------- | ----------------------- |
| `alumno_id`           | INTEGER   | FK to dim_student       |
| `anio_academico`      | INTEGER   | FK to dim_periodo       |
| `fecha_reinscripcion` | TIMESTAMP | Re-enrollment date      |
| `nro_transaccion`     | TEXT      | Transaction number      |
| `reinscription_count` | INTEGER   | Count metric (always 1) |

**Source**: `bronze.reinscripciones`

---

### `silver.fact_dropout` (Dropout Events) ⚠️ TARGET TABLE

**File**: `sql/silver/25_fact_dropout.sql`  
**Grain**: One row per student-year dropout event  
**Purpose**: **ML Target/Label** - Dropout events for prediction.

| Column                   | Type    | Description                 |
| ------------------------ | ------- | --------------------------- |
| `alumno_id`              | INTEGER | FK to dim_student           |
| `anio_academico`         | INTEGER | FK to dim_periodo           |
| `perdida_regularidad_id` | INTEGER | Event ID                    |
| `fecha_dropout`          | DATE    | Dropout date                |
| `fecha_control_desde`    | DATE    | Control period start        |
| `fecha_control_hasta`    | DATE    | Control period end          |
| `dropout_flag`           | INTEGER | **Target label (always 1)** |

**Source**: `bronze.perdida_regularidades`

**⚠️ ML Importance**: This is the primary target table for dropout prediction models.

---

### `silver.fact_student_status_history` (Status Changes)

**File**: `sql/silver/26_fact_student_status_history.sql`  
**Grain**: One row per student-status change event  
**Purpose**: Track changes in student quality/status.

| Column           | Type      | Description             |
| ---------------- | --------- | ----------------------- |
| `alumno_id`      | INTEGER   | FK to dim_student       |
| `fecha_cambio`   | TIMESTAMP | Change date             |
| `calidad`        | TEXT      | New quality/status code |
| `motivo_calidad` | TEXT      | Reason for change       |
| `nro_cambio`     | INTEGER   | Change sequence number  |

**Source**: `bronze.alumnos_hist_calidad`

**Notes**: `nro_cambio` is calculated using window function to track sequence of changes per student.

---

## Relationships

```
dim_student (alumno_id)
    ├── dim_persona (persona_id)
    ├── dim_propuesta (propuesta_id)
    ├── dim_plan_version (plan_version_id)
    ├── dim_facultad (facultad_id)
    └── dim_ubicacion (ubicacion_id)

dim_persona (persona_id)
    └── dim_census (persona_id)

fact_course_enrollment
    ├── dim_student (alumno_id)
    ├── dim_elemento (elemento_id)
    └── dim_plan_version (plan_version_id)

fact_academic_performance
    ├── dim_student (alumno_id)
    ├── dim_elemento (elemento_id)
    ├── dim_periodo (anio_academico)
    ├── dim_plan_version (plan_version_id)
    └── dim_instancia (instancia_id)

fact_exam_inscription
    ├── dim_student (alumno_id)
    ├── dim_elemento (elemento_id)
    ├── dim_instancia (instancia_id)
    └── dim_plan_version (plan_version_id)

fact_attendance
    ├── dim_student (alumno_id)
    └── dim_periodo (anio_academico)

fact_reinscription
    ├── dim_student (alumno_id)
    └── dim_periodo (anio_academico)

fact_dropout
    ├── dim_student (alumno_id)
    └── dim_periodo (anio_academico)

fact_student_status_history
    └── dim_student (alumno_id)
```

---

## Execution Order

Files are executed in alphabetical order by filename. The numeric prefix ensures correct dependency order:

```
01_dim_fecha.sql          # No dependencies
02_dim_periodo.sql        # Reads bronze tables
03_dim_propuesta.sql      # Reads bronze.students
03b_dim_facultad.sql      # Reads bronze.students
04_dim_plan_version.sql   # Reads bronze tables
05_dim_elemento.sql       # Reads bronze.elementos
06_dim_instancia.sql      # Reads bronze.instancias
07_dim_ubicacion.sql      # Reads bronze.students
08_dim_persona.sql        # Reads bronze.personas
09_dim_census.sql         # Reads bronze.census
10_dim_student.sql        # Depends on dim_facultad
20_fact_course_enrollment.sql
21_fact_academic_performance.sql
22_fact_exam_inscription.sql
23_fact_attendance.sql
24_fact_reinscription.sql
25_fact_dropout.sql
26_fact_student_status_history.sql
```
