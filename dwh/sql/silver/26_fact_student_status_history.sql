-- ============================================================================
-- FACT: fact_student_status_history (Student Quality/Status Changes)
-- Grain: One row per student-status change event
-- Tracks changes in student quality status over time
-- ============================================================================

CREATE OR REPLACE TABLE silver.fact_student_status_history AS
SELECT
    -- Keys
    alumno AS alumno_id,
    fecha AS fecha_cambio,
    
    -- Status details
    calidad,
    motivo_calidad,
    
    -- Derived: Order of status changes per student
    ROW_NUMBER() OVER (PARTITION BY alumno ORDER BY fecha) AS nro_cambio

FROM bronze.alumnos_hist_calidad
WHERE alumno IS NOT NULL;
