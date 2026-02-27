-- ============================================================================
-- FACT: fact_academic_performance (Academic Performance/Grades)
-- Grain: One row per student-course-period evaluation
-- Source: bronze.historia_academica (contains actual grades)
-- ============================================================================

CREATE OR REPLACE TABLE silver.fact_academic_performance AS
SELECT
    -- Keys
    ha.alumno AS alumno_id,
    ha.elemento AS elemento_id,
    ha.anio_academico::INTEGER AS anio_academico,
    ha.periodo_lectivo,
    ha.plan_version AS plan_version_id,
    ha.instancia AS instancia_id,
    
    -- Grade info
    ha.nota,
    ha.nota_descripcion,
    ha.resultado,
    ha.resultado_descripcion,
    ha.fecha AS fecha_evaluacion,
    ha.tipo AS tipo_evaluacion,
    ha.origen,
    
    -- Attendance
    ha.pct_asistencia,
    
    -- Credits
    ha.creditos,
    
    -- Derived metrics
    CASE 
        WHEN ha.resultado IN ('A', 'P', 'R') THEN 1 
        ELSE 0 
    END AS aprobado_flag,
    CASE 
        WHEN ha.resultado IN ('D', 'L', 'U') THEN 1 
        ELSE 0 
    END AS reprobado_flag,
    CASE 
        WHEN ha.resultado = 'A' THEN 1 
        ELSE 0 
    END AS ausente_flag,
    1 AS evaluation_count

FROM bronze.historia_academica ha
WHERE ha.alumno IS NOT NULL;
