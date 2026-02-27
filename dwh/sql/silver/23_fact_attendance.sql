-- ============================================================================
-- FACT: fact_attendance (Attendance Records)
-- Grain: One row per student-course-period
-- ============================================================================

CREATE OR REPLACE TABLE silver.fact_attendance AS
SELECT
    -- Keys
    alumno AS alumno_id,
    anio_academico,
    
    -- Attendance metrics
    porc_asistencia,
    total_inasistencias,
    
    -- Derived
    CASE 
        WHEN porc_asistencia >= 75 THEN 1 
        ELSE 0 
    END AS cumple_asistencia_flag,
    CASE 
        WHEN porc_asistencia < 50 THEN 1 
        ELSE 0 
    END AS riesgo_asistencia_flag

FROM bronze.attendance
WHERE alumno IS NOT NULL;
