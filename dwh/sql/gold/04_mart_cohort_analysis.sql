-- ============================================================================
-- GOLD: gold_cohort_analysis
-- Cohort-level aggregations for trend analysis, reporting, and model validation
-- Used for temporal cross-validation (train/validation split by cohorts)
-- ============================================================================

CREATE OR REPLACE TABLE gold.mart_cohort_analysis AS
WITH student_outcomes AS (
    SELECT
        ds.alumno_id,
        ds.anio_ingreso,
        ds.propuesta_id,
        ds.propuesta_nombre,
        ds.facultad_id,
        ds.facultad_nombre,
        ds.sede_provincia,
        
        -- Did this student ever dropout?
        MAX(CASE WHEN fd.dropout_flag = 1 THEN 1 ELSE 0 END) AS ever_dropped_out,
        MIN(fd.anio_academico) AS primer_anio_dropout,
        
        -- Years until dropout (if applicable)
        MIN(fd.anio_academico) - ds.anio_ingreso AS anios_hasta_dropout,
        
        -- Academic performance summary
        AVG(TRY_CAST(ha.nota AS DOUBLE)) AS promedio_notas_global,
        SUM(ha.aprobado_flag) AS total_aprobadas,
        SUM(ha.reprobado_flag) AS total_reprobadas
        
    FROM silver.dim_student ds
    LEFT JOIN silver.fact_dropout fd ON ds.alumno_id = fd.alumno_id
    LEFT JOIN silver.fact_academic_performance ha ON ds.alumno_id = ha.alumno_id
    WHERE ds.anio_ingreso IS NOT NULL
    GROUP BY
        ds.alumno_id,
        ds.anio_ingreso,
        ds.propuesta_id,
        ds.propuesta_nombre,
        ds.facultad_id,
        ds.facultad_nombre,
        ds.sede_provincia
)
SELECT
    anio_ingreso AS cohorte,
    propuesta_id,
    propuesta_nombre,
    facultad_id,
    facultad_nombre,
    sede_provincia,
    
    -- Cohort size
    COUNT(*) AS total_estudiantes,
    
    -- Dropout metrics
    SUM(ever_dropped_out) AS total_desertores,
    ROUND(SUM(ever_dropped_out)::FLOAT / COUNT(*) * 100, 2) AS tasa_desercion_pct,
    
    -- Retention
    COUNT(*) - SUM(ever_dropped_out) AS total_retenidos,
    ROUND((COUNT(*) - SUM(ever_dropped_out))::FLOAT / COUNT(*) * 100, 2) AS tasa_retencion_pct,
    
    -- Time to dropout analysis
    AVG(anios_hasta_dropout) AS promedio_anios_hasta_dropout,
    MIN(anios_hasta_dropout) AS min_anios_hasta_dropout,
    MAX(anios_hasta_dropout) AS max_anios_hasta_dropout,
    
    -- Academic performance by cohort
    AVG(promedio_notas_global) AS promedio_notas_cohorte,
    ROUND(SUM(total_aprobadas)::FLOAT / NULLIF(SUM(total_aprobadas) + SUM(total_reprobadas), 0) * 100, 2) AS tasa_aprobacion_cohorte_pct
    
FROM student_outcomes
GROUP BY
    anio_ingreso,
    propuesta_id,
    propuesta_nombre,
    facultad_id,
    facultad_nombre,
    sede_provincia
ORDER BY anio_ingreso DESC, propuesta_nombre;
