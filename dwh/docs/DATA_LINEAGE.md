# Data Lineage Documentation

## Overview

This document traces the complete data lineage from source systems through the Medallion Architecture layers to the final ML training dataset. Understanding data lineage is critical for:

- **Data Quality**: Tracing issues back to their source
- **Impact Analysis**: Understanding downstream effects of source changes
- **Compliance**: Documenting data provenance for audits
- **Debugging**: Troubleshooting data pipeline issues

---

## End-to-End Data Flow

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              SOURCE SYSTEMS                                      │
│                            (SIU Guaraní - PostgreSQL)                           │
├─────────────────────────────────────────────────────────────────────────────────┤
│  negocio.sga_alumnos              negocio.mdp_personas                          │
│  negocio.sga_propuestas           negocio.sga_elementos                         │
│  negocio.sga_insc_cursada         negocio.sga_insc_examen                       │
│  negocio.sga_evaluaciones         negocio.sga_reinscripciones                   │
│  negocio.sga_perdida_regularidad  negocio.mdp_datos_personales                  │
│  negocio.sga_alumnos_hist_calidad negocio.vw_hist_academica                     │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        │ dlt (Extraction)
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              BRONZE LAYER                                        │
│                             (Raw Landing Zone)                                   │
├─────────────────────────────────────────────────────────────────────────────────┤
│  bronze.students            bronze.personas             bronze.elementos        │
│  bronze.instancias          bronze.academic             bronze.census           │
│  bronze.dropout             bronze.attendance           bronze.historia_academica│
│  bronze.exam_inscriptions   bronze.course_inscriptions  bronze.reinscripciones  │
│  bronze.alumnos_hist_calidad bronze.perdida_regularidades                       │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        │ SQL (CREATE OR REPLACE)
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              SILVER LAYER                                        │
│                          (Dimensional Model - Star Schema)                       │
├─────────────────────────────────────────────────────────────────────────────────┤
│  DIMENSIONS:                                                                     │
│  silver.dim_fecha           silver.dim_periodo          silver.dim_propuesta    │
│  silver.dim_facultad        silver.dim_plan_version     silver.dim_elemento     │
│  silver.dim_instancia       silver.dim_ubicacion        silver.dim_persona      │
│  silver.dim_census          silver.dim_student                                   │
│                                                                                  │
│  FACTS:                                                                          │
│  silver.fact_course_enrollment    silver.fact_academic_performance              │
│  silver.fact_exam_inscription     silver.fact_attendance                        │
│  silver.fact_reinscription        silver.fact_dropout                           │
│  silver.fact_student_status_history                                              │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        │ SQL (Aggregations)
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                               GOLD LAYER                                         │
│                    (Business Aggregations & ML Features)                         │
├─────────────────────────────────────────────────────────────────────────────────┤
│  DATA MARTS:                                                                     │
│  gold.mart_student_academic_summary   gold.mart_student_engagement              │
│  gold.mart_student_risk_features      gold.mart_cohort_analysis                 │
│                                                                                  │
│  TFT FEATURE STORE:                                                              │
│  gold.gold_tft_static_features        gold.gold_tft_temporal_features           │
│  gold.gold_tft_known_future           gold.gold_tft_training_dataset            │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## Source to Bronze Lineage

### Student Master Data

```
SOURCE                              BRONZE                    BRONZE COLUMN
─────────────────────────────────────────────────────────────────────────────
negocio.sga_alumnos.alumno      → bronze.students         → alumno
negocio.sga_alumnos.persona     → bronze.students         → persona
negocio.sga_alumnos.propuesta   → bronze.students         → propuesta
negocio.sga_propuestas.nombre   → bronze.students         → propuesta_nombre
negocio.sga_alumnos.plan_version→ bronze.students         → plan_version_id
negocio.sga_planes_versiones.nombre → bronze.students     → plan_version
negocio.sga_alumnos.ubicacion   → bronze.students         → ubicacion
negocio.sga_ubicaciones.*       → bronze.students         → see_*
negocio.int_arau_instituciones.* → bronze.students        → see_institucion*
negocio.mug_localidades.nombre  → bronze.students         → see_localidad
negocio.mug_dptos_partidos.nombre → bronze.students       → see_dpto
negocio.mug_provincias.nombre   → bronze.students         → see_provincia
negocio.sga_alumnos.modalidad   → bronze.students         → modalidad
negocio.sga_alumnos.regular     → bronze.students         → regular
negocio.sga_propuestas_aspira.fecha_inscripcion → bronze.students → fecha_ingreso
negocio.sga_propuestas_aspira.tipo_ingreso → bronze.students → tipo_ingreso
```

### Person Demographics

```
SOURCE                              BRONZE                    BRONZE COLUMN
─────────────────────────────────────────────────────────────────────────────
negocio.mdp_personas.persona    → bronze.personas         → persona
negocio.mdp_personas.fecha_nacimiento → bronze.personas   → fecha_nacimiento
negocio.mdp_personas.sexo       → bronze.personas         → sexo
negocio.mdp_personas.localidad_nacimiento → bronze.personas → localidad_nacimiento
negocio.mug_localidades.nombre  → bronze.personas         → localidad_nacimiento_desc
negocio.mdp_personas.nacionalidad → bronze.personas       → nacionalidad
negocio.mdp_nacionalidades.descripcion → bronze.personas  → nacionalidad_desc
```

### Academic Performance

```
SOURCE                              BRONZE                    BRONZE COLUMN
─────────────────────────────────────────────────────────────────────────────
negocio.sga_insc_cursada.alumno → bronze.academic         → alumno
negocio.sga_periodos.anio_academico → bronze.academic     → anio_academico
negocio.sga_comisiones.elemento → bronze.academic         → elemento
negocio.sga_eval_detalle_cursadas.nota_cursada → bronze.academic → nota_cursada
negocio.sga_eval_detalle_cursadas.resultado_cursada → bronze.academic → resultado_cursada
negocio.sga_eval_detalle_cursadas.fecha_regular → bronze.academic → fecha_nota

negocio.vw_hist_academica.*     → bronze.historia_academica → *
```

### Census/Socioeconomic

```
SOURCE                              BRONZE                    BRONZE COLUMN
─────────────────────────────────────────────────────────────────────────────
negocio.mdp_preguntas_censo.persona → bronze.census       → persona
negocio.mdp_preguntas_censo.fecha_relevamiento → bronze.census → fecha
negocio.mdp_datos_personales.estado_civil → bronze.census → estado_civil
negocio.mdp_datos_personales.cantidad_hijos → bronze.census → cantidad_hijos
negocio.mdp_datos_personales.tipo_vivienda → bronze.census → tipo_vivienda
negocio.mdp_datos_personales.vive_con → bronze.census     → vive_con
negocio.mdp_datos_personales.periodo_lectivo_* → bronze.census → periodo_lectivo_*
negocio.mdp_datos_economicos.trabajo_existe → bronze.census → trabajo_existe
negocio.mdp_datos_economicos.trabajo_hora_sem → bronze.census → trabajo_hora_sem
negocio.mdp_datos_economicos.beca → bronze.census         → beca
negocio.mdp_datos_economicos.costeo_estudios_* → bronze.census → costeos_estudios_*
negocio.mdp_datos_actividades.tecnologia_* → bronze.census → tecnologia_*
negocio.mdp_datos_discapacidad.* → bronze.census          → disc_*
negocio.mdp_datos_estudios.nivel_estudio → bronze.census  → nivel_estudio
negocio.mdp_datos_estudios.institucion → bronze.census    → institucion
```

### Dropout Events

```
SOURCE                              BRONZE                    BRONZE COLUMN
─────────────────────────────────────────────────────────────────────────────
negocio.sga_perdida_regularidad.alumno → bronze.dropout   → alumno
negocio.sga_perdida_regularidad.anio_academico → bronze.dropout → anio_academico
negocio.sga_perdida_regularidad.fecha → bronze.dropout    → fecha_dropout
```

---

## Bronze to Silver Lineage

### Dimension Tables

#### dim_student

```
BRONZE                              SILVER.DIM_STUDENT
─────────────────────────────────────────────────────────────────────────────
bronze.students.alumno          → alumno_id
bronze.students.persona         → persona_id
bronze.students.propuesta       → propuesta_id
bronze.students.propuesta_nombre → propuesta_nombre
bronze.students.plan_version_id → plan_version_id
bronze.students.plan_version    → plan_version
bronze.students.ubicacion       → ubicacion_id
bronze.students.see_provincia   → sede_provincia
bronze.students.modalidad       → modalidad
bronze.students.regular         → es_regular
bronze.students.fecha_ingreso   → fecha_ingreso
bronze.students.tipo_ingreso    → tipo_ingreso
DERIVED: YEAR(fecha_ingreso)    → anio_ingreso
DERIVED: DATE_DIFF(...)         → antiguedad_anios
JOINED: silver.dim_facultad     → facultad_id, facultad_nombre, universidad_nombre,
                                   tipo_sede, ubicacion_sede
```

#### dim_persona

```
BRONZE                              SILVER.DIM_PERSONA
─────────────────────────────────────────────────────────────────────────────
bronze.personas.persona         → persona_id
bronze.personas.fecha_nacimiento → fecha_nacimiento
DERIVED: DATE_DIFF(...)         → edad_actual
bronze.personas.sexo            → sexo
bronze.personas.localidad_nacimiento → localidad_nacimiento
bronze.personas.localidad_nacimiento_desc → localidad_nacimiento_desc
bronze.personas.nacionalidad    → nacionalidad
bronze.personas.nacionalidad_desc → nacionalidad_desc
```

#### dim_census

```
BRONZE                              SILVER.DIM_CENSUS
─────────────────────────────────────────────────────────────────────────────
bronze.census.persona           → persona_id
bronze.census.fecha             → fecha_relevamiento
bronze.census.estado_civil      → estado_civil
bronze.census.estado_civil_desc → estado_civil_desc
bronze.census.cantidad_hijos    → cantidad_hijos
bronze.census.vive_con          → vive_con
bronze.census.cobertura_salud   → cobertura_salud
bronze.census.tipo_vivienda     → tipo_vivienda
bronze.census.trabajo_existe    → trabajo_existe
bronze.census.trabajo_hora_sem  → trabajo_hora_sem
bronze.census.beca              → beca
bronze.census.costeos_estudios_* → costeos_estudios_*
bronze.census.tecnologia_*      → tecnologia_*
bronze.census.disc_*            → disc_*
bronze.census.nivel_estudio     → nivel_estudio_previo
bronze.census.institucion       → institucion_previa_id
bronze.census.colegio           → colegio_secundario_id
```

### Fact Tables

#### fact_academic_performance

```
BRONZE                              SILVER.FACT_ACADEMIC_PERFORMANCE
─────────────────────────────────────────────────────────────────────────────
bronze.historia_academica.alumno → alumno_id
bronze.historia_academica.elemento → elemento_id
bronze.historia_academica.anio_academico → anio_academico
bronze.historia_academica.periodo_lectivo → periodo_lectivo
bronze.historia_academica.plan_version → plan_version_id
bronze.historia_academica.instancia → instancia_id
bronze.historia_academica.nota  → nota
bronze.historia_academica.nota_descripcion → nota_descripcion
bronze.historia_academica.resultado → resultado
bronze.historia_academica.resultado_descripcion → resultado_descripcion
bronze.historia_academica.fecha → fecha_evaluacion
bronze.historia_academica.tipo  → tipo_evaluacion
bronze.historia_academica.origen → origen
bronze.historia_academica.pct_asistencia → pct_asistencia
bronze.historia_academica.creditos → creditos
DERIVED: CASE resultado IN (A,P,R) → aprobado_flag
DERIVED: CASE resultado IN (D,L,U) → reprobado_flag
DERIVED: CASE resultado = 'A'   → ausente_flag
CONSTANT: 1                     → evaluation_count
```

#### fact_dropout (TARGET TABLE)

```
BRONZE                              SILVER.FACT_DROPOUT
─────────────────────────────────────────────────────────────────────────────
bronze.perdida_regularidades.alumno → alumno_id
bronze.perdida_regularidades.anio_academico → anio_academico
bronze.perdida_regularidades.perdida_regularidad → perdida_regularidad_id
bronze.perdida_regularidades.fecha → fecha_dropout
bronze.perdida_regularidades.fecha_control_desde → fecha_control_desde
bronze.perdida_regularidades.fecha_control_hasta → fecha_control_hasta
CONSTANT: 1                     → dropout_flag
```

---

## Silver to Gold Lineage

### mart_student_academic_summary

```
SILVER                              GOLD.MART_STUDENT_ACADEMIC_SUMMARY
─────────────────────────────────────────────────────────────────────────────
fact_academic_performance.alumno_id → alumno_id
fact_academic_performance.anio_academico → anio_academico
AGG: COUNT(*)                   → total_evaluaciones
AGG: COUNT(DISTINCT elemento_id) → materias_cursadas
AGG: AVG(nota)                  → promedio_notas
AGG: MIN(nota)                  → nota_minima
AGG: MAX(nota)                  → nota_maxima
AGG: STDDEV(nota)               → desviacion_notas
AGG: SUM(aprobado_flag)         → materias_aprobadas
AGG: SUM(reprobado_flag)        → materias_reprobadas
AGG: SUM(ausente_flag)          → materias_ausente
DERIVED: aprobadas/total        → tasa_aprobacion
DERIVED: reprobadas/total       → tasa_reprobacion
DERIVED: ausentes/total         → tasa_ausentismo
WINDOW: SUM(...) OVER (...)     → *_acum (cumulative)
WINDOW: AVG(...) OVER (...)     → promedio_historico
WINDOW: LAG(...) OVER (...)     → variacion_* (YoY changes)
```

### mart_student_risk_features

```
SOURCES                             GOLD.MART_STUDENT_RISK_FEATURES
─────────────────────────────────────────────────────────────────────────────
silver.dim_student              → Student characteristics
silver.dim_persona              → Demographics
silver.dim_census               → Socioeconomic features
gold.mart_student_academic_summary → Academic performance
gold.mart_student_engagement    → Engagement metrics
silver.fact_dropout             → dropout_label (TARGET)
silver.fact_student_status_history → total_cambios_estado

DERIVED RISK INDICATORS:
tasa_aprobacion < 0.5           → riesgo_academico
promedio_asistencia < 60        → riesgo_asistencia
reinscripciones_anio = 0        → riesgo_no_reinscripcion
trabajo_hora_sem > 30           → riesgo_trabajo_excesivo
SUM(risk indicators * weights)  → risk_score_heuristic
```

### gold_tft_training_dataset (Final ML Dataset)

```
SOURCES                             GOLD.GOLD_TFT_TRAINING_DATASET
─────────────────────────────────────────────────────────────────────────────
gold.gold_tft_temporal_features → Identifiers, Time-varying features, Target
gold.gold_tft_static_features   → Static covariates (demographics, socioeconomic)
gold.gold_tft_known_future      → Calendar features (known in advance)

JOIN KEYS:
temporal_features.alumno_id = static_features.alumno_id
temporal_features.anio_academico = known_future.anio_academico

DERIVED SEQUENCE METADATA:
COUNT(*) OVER (PARTITION BY alumno_id) → sequence_length
CASE WHEN time_step = MAX(time_step)   → is_last_observation
```

---

## Target Variable Lineage

The target variable for ML models (`dropout_flag`) has the following lineage:

```
┌────────────────────────────────────────┐
│ negocio.sga_perdida_regularidad        │  SOURCE
│ (Student regularity loss table)        │
└────────────────────────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────┐
│ bronze.perdida_regularidades           │  BRONZE
│ (Raw extraction with source_db)        │
└────────────────────────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────┐
│ silver.fact_dropout                    │  SILVER
│ dropout_flag = 1 (always)              │
│ Grain: student-year-event              │
└────────────────────────────────────────┘
                    │
              ┌─────┴─────┐
              ▼           ▼
┌─────────────────────┐  ┌─────────────────────┐
│ gold.mart_student_  │  │ gold.gold_tft_      │  GOLD
│ risk_features       │  │ temporal_features   │
│                     │  │                     │
│ dropout_label       │  │ dropout_flag        │
│ (0 or 1)            │  │ dropout_next_year   │
└─────────────────────┘  └─────────────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────┐
                    │ gold.gold_tft_training_ │  FINAL
                    │ dataset                 │
                    │                         │
                    │ dropout_flag            │
                    │ dropout_next_year       │
                    │ fecha_dropout           │
                    └─────────────────────────┘
```

**Target Definition**:

- `dropout_flag`: 1 if student lost regularity in this academic year, 0 otherwise
- `dropout_next_year`: 1 if student will dropout in the next academic year (for forward prediction)

---

## Data Quality Checkpoints

### Bronze Layer

- [ ] `source_db` populated for all records
- [ ] Incremental cursors advancing correctly
- [ ] No duplicate records (check `dwh_pk` for historia_academica)

### Silver Layer

- [ ] All dimension primary keys are unique and non-null
- [ ] Foreign key relationships are valid
- [ ] Derived flags match business logic

### Gold Layer

- [ ] Aggregations sum correctly
- [ ] Window functions produce expected cumulative values
- [ ] Target variable distribution is as expected

---

## Impact Analysis Matrix

When a source table changes, use this matrix to identify affected targets:

| Source Change              | Affected Bronze                | Affected Silver                           | Affected Gold             |
| -------------------------- | ------------------------------ | ----------------------------------------- | ------------------------- |
| sga_alumnos                | students                       | dim_student, dim_propuesta, dim_ubicacion | All marts, TFT features   |
| mdp_personas               | personas                       | dim_persona                               | mart_risk, TFT static     |
| mdp_datos_personales       | census                         | dim_census                                | mart_risk, TFT static     |
| sga_perdida_regularidad    | dropout, perdida_regularidades | fact_dropout                              | All marts, TFT (target)   |
| vw_hist_academica          | historia_academica             | fact_academic_performance                 | All academic aggregations |
| sga_insc_cursada           | academic, course_inscriptions  | fact_course_enrollment, fact_academic     | Academic marts            |
| sga_insc_examen            | exam_inscriptions              | fact_exam_inscription                     | Engagement marts          |
| sga_reinscripciones        | reinscripciones                | fact_reinscription                        | Engagement marts          |
| sga_clases_asistencia_acum | attendance                     | fact_attendance                           | Engagement marts          |
| sga_alumnos_hist_calidad   | alumnos_hist_calidad           | fact_student_status_history               | Risk features             |
