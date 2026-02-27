# Bronze Layer Catalog

## Overview

The Bronze layer contains raw data extracted from source systems (SIU Guaraní) with minimal transformation. Data is stored exactly as received from sources, with an added `source_db` column to track multi-tenant origins.

## Source System

| System      | Type       | Database           | Purpose                    |
| ----------- | ---------- | ------------------ | -------------------------- |
| SIU Guaraní | PostgreSQL | Multiple instances | Academic management system |

## Extraction Patterns

The pipeline supports two extraction strategies:

### Full Refresh (`write_disposition="replace"`)

- Entire table is replaced on each run
- Used for small, frequently changing reference tables
- Suitable for master data and configurations

### Incremental Append (`write_disposition="append"`)

- Only new/changed records are extracted based on cursor column
- Used for large event/history tables
- Reduces extraction time and source system load

---

## Table Catalog

### `bronze.students`

**Description**: Master student enrollment records linking students to academic programs.

| Extraction | Disposition | Cursor | Initial Value |
| ---------- | ----------- | ------ | ------------- |
| Full       | Replace     | N/A    | N/A           |

**Source Query**: `sql/bronze/students.sql`

| Column              | Type    | Description                            |
| ------------------- | ------- | -------------------------------------- |
| `alumno`            | INTEGER | Student ID (primary key in source)     |
| `persona`           | INTEGER | Person ID (FK to personas)             |
| `propuesta`         | INTEGER | Academic program/proposal ID           |
| `propuesta_nombre`  | TEXT    | Program name                           |
| `propuesta_codigo`  | TEXT    | Program code                           |
| `plan_version_id`   | INTEGER | Study plan version ID                  |
| `plan_version`      | TEXT    | Study plan version name                |
| `ubicacion`         | INTEGER | Campus/location ID                     |
| `see_nombre`        | TEXT    | Location name                          |
| `see_calle`         | TEXT    | Location street                        |
| `see_numero`        | TEXT    | Location street number                 |
| `see_codigo_postal` | TEXT    | Location postal code                   |
| `see_institucion`   | TEXT    | Institution name                       |
| `see_institucion_p` | TEXT    | Parent institution name                |
| `see_localidad`     | TEXT    | Location city                          |
| `see_dpto`          | TEXT    | Location department                    |
| `see_provincia`     | TEXT    | Location province                      |
| `modalidad`         | TEXT    | Study modality (presencial, distancia) |
| `regular`           | BOOLEAN | Current regularity status              |
| `fecha_ingreso`     | DATE    | Enrollment date                        |
| `tipo_ingreso`      | TEXT    | Admission type                         |
| `source_db`         | TEXT    | Source database identifier             |

---

### `bronze.personas`

**Description**: Person demographic information.

| Extraction | Disposition | Cursor | Initial Value |
| ---------- | ----------- | ------ | ------------- |
| Full       | Replace     | N/A    | N/A           |

**Source Query**: `sql/bronze/personas.sql`

| Column                      | Type    | Description                |
| --------------------------- | ------- | -------------------------- |
| `persona`                   | INTEGER | Person ID (primary key)    |
| `fecha_nacimiento`          | DATE    | Birth date                 |
| `sexo`                      | TEXT    | Gender (M/F)               |
| `localidad_nacimiento`      | INTEGER | Birth city ID              |
| `localidad_nacimiento_desc` | TEXT    | Birth city name            |
| `nacionalidad`              | INTEGER | Nationality ID             |
| `nacionalidad_desc`         | TEXT    | Nationality description    |
| `source_db`                 | TEXT    | Source database identifier |

---

### `bronze.elementos`

**Description**: Course/subject catalog.

| Extraction | Disposition | Cursor | Initial Value |
| ---------- | ----------- | ------ | ------------- |
| Full       | Replace     | N/A    | N/A           |

**Source Query**: `sql/bronze/elementos.sql`

| Column           | Type    | Description                     |
| ---------------- | ------- | ------------------------------- |
| `elemento`       | INTEGER | Element/course ID (primary key) |
| `materia_codigo` | TEXT    | Course code                     |
| `materia_nombre` | TEXT    | Course name                     |
| `source_db`      | TEXT    | Source database identifier      |

---

### `bronze.instancias`

**Description**: Exam instance types catalog.

| Extraction | Disposition | Cursor | Initial Value |
| ---------- | ----------- | ------ | ------------- |
| Full       | Replace     | N/A    | N/A           |

**Source Query**: `sql/bronze/instancias.sql`

| Column             | Type    | Description                |
| ------------------ | ------- | -------------------------- |
| `instancia`        | INTEGER | Instance ID (primary key)  |
| `instancia_nombre` | TEXT    | Instance type name         |
| `source_db`        | TEXT    | Source database identifier |

---

### `bronze.academic`

**Description**: Academic performance records (grades, course results).

| Extraction  | Disposition | Cursor       | Initial Value |
| ----------- | ----------- | ------------ | ------------- |
| Incremental | Append      | `fecha_nota` | 1900-01-01    |

**Source Query**: `sql/bronze/academic.sql`

| Column              | Type    | Description                                |
| ------------------- | ------- | ------------------------------------------ |
| `alumno`            | INTEGER | Student ID                                 |
| `anio_academico`    | INTEGER | Academic year                              |
| `periodo_lectivo`   | INTEGER | Academic period                            |
| `elemento`          | INTEGER | Course ID                                  |
| `nota_cursada`      | NUMERIC | Course grade (converted from text)         |
| `resultado_cursada` | TEXT    | Course result (A=Approved, R=Failed, etc.) |
| `fecha_nota`        | DATE    | Grade date (cursor column)                 |
| `source_db`         | TEXT    | Source database identifier                 |

**Business Rules**:

- Grades are converted from text to numeric, with non-numeric values becoming NULL
- Only records with non-null `anio_academico` are included

---

### `bronze.census`

**Description**: Socioeconomic census data collected from students.

| Extraction  | Disposition | Cursor  | Initial Value |
| ----------- | ----------- | ------- | ------------- |
| Incremental | Append      | `fecha` | 1900-01-01    |

**Source Query**: `sql/bronze/census.sql`

| Column                 | Type    | Description                    |
| ---------------------- | ------- | ------------------------------ |
| `persona`              | INTEGER | Person ID                      |
| `fecha`                | DATE    | Survey date (cursor column)    |
| `estado_civil`         | INTEGER | Marital status code            |
| `estado_civil_desc`    | TEXT    | Marital status description     |
| `union_pareja`         | BOOLEAN | Has partner                    |
| `situacion_padre`      | TEXT    | Father's situation             |
| `situacion_madre`      | TEXT    | Mother's situation             |
| `cobertura_salud`      | TEXT    | Health coverage type           |
| `cantidad_hijos`       | INTEGER | Number of children             |
| `tipo_vivienda`        | INTEGER | Housing type code              |
| `tipo_vivienda_desc`   | TEXT    | Housing type description       |
| `vive_con`             | TEXT    | Lives with                     |
| `periodo_lectivo_*`    | TEXT    | Academic period address fields |
| `procedencia_*`        | TEXT    | Origin address fields          |
| `trabajo_existe`       | BOOLEAN | Currently employed             |
| `trabajo_existe_desc`  | TEXT    | Employment description         |
| `trabajo_hora_sem`     | INTEGER | Weekly work hours              |
| `beca`                 | BOOLEAN | Has scholarship                |
| `costeos_estudios_*`   | BOOLEAN | Study funding sources          |
| `tecnologia_int_casa`  | BOOLEAN | Internet at home               |
| `tecnologia_pc_casa`   | BOOLEAN | Computer at home               |
| `tecnologia_int_movil` | BOOLEAN | Mobile internet                |
| `deportes`             | BOOLEAN | Practices sports               |
| `disc_auditiva`        | BOOLEAN | Hearing disability             |
| `disc_visual`          | BOOLEAN | Visual disability              |
| `disc_motora`          | BOOLEAN | Motor disability               |
| `nivel_estudio`        | INTEGER | Previous education level       |
| `nivel_estudio_desc`   | TEXT    | Education level description    |
| `institucion`          | INTEGER | Previous institution ID        |
| `institucion_desc`     | TEXT    | Previous institution name      |
| `source_db`            | TEXT    | Source database identifier     |

**Notes**:

- Uses ranked CTE to handle multiple census entries per person
- Contains extensive socioeconomic features for ML models

---

### `bronze.dropout`

**Description**: Student dropout/regularity loss events.

| Extraction  | Disposition | Cursor          | Initial Value |
| ----------- | ----------- | --------------- | ------------- |
| Incremental | Append      | `fecha_dropout` | 1900-01-01    |

**Source Query**: `sql/bronze/dropout.sql`

| Column           | Type    | Description                  |
| ---------------- | ------- | ---------------------------- |
| `alumno`         | INTEGER | Student ID                   |
| `anio_academico` | INTEGER | Academic year of dropout     |
| `fecha_dropout`  | DATE    | Dropout date (cursor column) |
| `source_db`      | TEXT    | Source database identifier   |

**Source Table**: `negocio.sga_perdida_regularidad`

---

### `bronze.attendance`

**Description**: Accumulated attendance records.

| Extraction | Disposition | Cursor | Initial Value |
| ---------- | ----------- | ------ | ------------- |
| Full       | Replace     | N/A    | N/A           |

**Source Query**: `sql/bronze/attendance.sql`

| Column                | Type    | Description                |
| --------------------- | ------- | -------------------------- |
| `alumno`              | INTEGER | Student ID                 |
| `anio_academico`      | INTEGER | Academic year              |
| `porc_asistencia`     | NUMERIC | Attendance percentage      |
| `total_inasistencias` | INTEGER | Total absences             |
| `source_db`           | TEXT    | Source database identifier |

---

### `bronze.historia_academica`

**Description**: Complete academic history including exams and grades.

| Extraction  | Disposition | Cursor  | Initial Value |
| ----------- | ----------- | ------- | ------------- |
| Incremental | Append      | `fecha` | 1900-01-01    |

**Source Query**: `sql/bronze/historia_academica.sql`  
**Fallback Query**: `sql/bronze/historia_academica_fallback.sql`

| Column              | Type    | Description                       |
| ------------------- | ------- | --------------------------------- |
| `dwh_pk`            | TEXT    | Generated primary key (SHA1 hash) |
| `persona`           | INTEGER | Person ID                         |
| `alumno`            | INTEGER | Student ID                        |
| `elemento`          | INTEGER | Course ID                         |
| `elemento_revision` | INTEGER | Course revision                   |
| `instancia`         | INTEGER | Exam instance type                |
| `fecha`             | DATE    | Record date (cursor column)       |
| `nota`              | NUMERIC | Grade                             |
| `resultado`         | TEXT    | Result code                       |
| `nro_resolucion`    | TEXT    | Resolution number                 |
| `source_db`         | TEXT    | Source database identifier        |

**Notes**:

- Has fallback query for schema variations
- Uses `dwh_pk` as primary key for deduplication
- Cursor coercion handles DATE vs TIMESTAMPTZ variations

---

### `bronze.exam_inscriptions`

**Description**: Exam enrollment records.

| Extraction  | Disposition | Cursor              | Initial Value |
| ----------- | ----------- | ------------------- | ------------- |
| Incremental | Append      | `fecha_mesa_examen` | 1900-01-01    |

**Source Query**: `sql/bronze/exam_inscriptions.sql`

| Column              | Type    | Description                |
| ------------------- | ------- | -------------------------- |
| `alumno`            | INTEGER | Student ID                 |
| `inscripcion_id`    | INTEGER | Enrollment ID              |
| `elemento_id`       | INTEGER | Course ID                  |
| `catedra_cod`       | TEXT    | Course code                |
| `catedra_nombre`    | TEXT    | Course name                |
| `fecha_mesa_examen` | DATE    | Exam date (cursor column)  |
| `instancia_id`      | INTEGER | Exam instance type ID      |
| `instancia_desc`    | TEXT    | Instance type description  |
| `plan_version_id`   | INTEGER | Study plan version ID      |
| `plan_version_desc` | TEXT    | Study plan version name    |
| `source_db`         | TEXT    | Source database identifier |

---

### `bronze.course_inscriptions`

**Description**: Course enrollment records.

| Extraction  | Disposition | Cursor              | Initial Value         |
| ----------- | ----------- | ------------------- | --------------------- |
| Incremental | Append      | `fecha_inscripcion` | 1900-01-01 (datetime) |

**Source Query**: `sql/bronze/course_inscriptions.sql`

| Column               | Type      | Description                     |
| -------------------- | --------- | ------------------------------- |
| `alumno`             | INTEGER   | Student ID                      |
| `inscripcion_id`     | INTEGER   | Enrollment ID                   |
| `elemento_id`        | INTEGER   | Course ID                       |
| `catedra_cod`        | TEXT      | Course code                     |
| `catedra_nombre`     | TEXT      | Course name                     |
| `periodo_lectivo`    | TEXT      | Academic period name            |
| `plan_version_id`    | INTEGER   | Study plan version ID           |
| `plan_version_desc`  | TEXT      | Study plan version name         |
| `fecha_inscripcion`  | TIMESTAMP | Enrollment date (cursor column) |
| `estado_inscripcion` | TEXT      | Enrollment status               |
| `source_db`          | TEXT      | Source database identifier      |

---

### `bronze.reinscripciones`

**Description**: Annual re-enrollment records.

| Extraction  | Disposition | Cursor                | Initial Value         |
| ----------- | ----------- | --------------------- | --------------------- |
| Incremental | Append      | `fecha_reinscripcion` | 1900-01-01 (datetime) |

**Source Query**: `sql/bronze/reinscripciones.sql`

| Column                | Type      | Description                        |
| --------------------- | --------- | ---------------------------------- |
| `alumno`              | INTEGER   | Student ID                         |
| `anio_academico`      | INTEGER   | Academic year                      |
| `fecha_reinscripcion` | TIMESTAMP | Re-enrollment date (cursor column) |
| `nro_transaccion`     | TEXT      | Transaction number                 |
| `source_db`           | TEXT      | Source database identifier         |

---

### `bronze.alumnos_hist_calidad`

**Description**: Student status/quality change history.

| Extraction  | Disposition | Cursor  | Initial Value                   |
| ----------- | ----------- | ------- | ------------------------------- |
| Incremental | Append      | `fecha` | 1900-01-01 (datetime, tz-aware) |

**Source Query**: `sql/bronze/alumnos_hist_calidad.sql`

| Column           | Type      | Description                        |
| ---------------- | --------- | ---------------------------------- |
| `alumno`         | INTEGER   | Student ID                         |
| `fecha`          | TIMESTAMP | Status change date (cursor column) |
| `motivo_calidad` | TEXT      | Reason for status change           |
| `calidad`        | TEXT      | New quality/status code            |
| `source_db`      | TEXT      | Source database identifier         |

---

### `bronze.perdida_regularidades`

**Description**: Regularity loss events.

| Extraction  | Disposition | Cursor  | Initial Value |
| ----------- | ----------- | ------- | ------------- |
| Incremental | Append      | `fecha` | 1900-01-01    |

**Source Query**: `sql/bronze/perdida_regularidades.sql`

| Column           | Type    | Description                |
| ---------------- | ------- | -------------------------- |
| `alumno`         | INTEGER | Student ID                 |
| `fecha`          | DATE    | Loss date (cursor column)  |
| `anio_academico` | INTEGER | Academic year              |
| `source_db`      | TEXT    | Source database identifier |

---

## Multi-Source Handling

All Bronze tables include a `source_db` column that identifies the originating database:

```python
SOURCE_DATABASES = [
    {"name": "guarani_sede_1", "conn_string": "..."},
    {"name": "guarani_sede_2", "conn_string": "..."},
]
```

This enables:

- Tracking data provenance
- Multi-tenant data consolidation
- Source-specific filtering in downstream layers

## Technical Notes

### Cursor Coercion

Different source databases may return DATE or TIMESTAMPTZ for the same column. The pipeline automatically coerces cursor values to maintain compatibility:

```python
def _coerce_incremental_value(value, target):
    # Converts between date and datetime as needed
```

### Fallback Queries

For tables with schema variations between sources, fallback queries handle missing columns gracefully:

```python
historia_academica = _resource_for_query_incremental_optional(
    ...,
    fallback_sql=_read_sql("historia_academica_fallback.sql"),
)
```

### Generated Primary Keys

For tables without natural keys (like `historia_academica`), a `dwh_pk` is generated:

```python
pk_parts = [source_name, persona, alumno, elemento, ...]
record["dwh_pk"] = hashlib.sha1("|".join(pk_parts)).hexdigest()
```
