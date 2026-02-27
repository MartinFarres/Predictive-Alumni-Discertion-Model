-- ============================================================================
-- FACT: fact_reinscription (Annual Re-enrollment Events)
-- Grain: One row per student-year re-enrollment
-- ============================================================================

CREATE OR REPLACE TABLE silver.fact_reinscription AS
SELECT
    -- Keys
    alumno AS alumno_id,
    anio_academico,
    
    -- Re-enrollment details
    fecha_reinscripcion,
    nro_transaccion,
    
    -- Metrics
    1 AS reinscription_count

FROM bronze.reinscripciones
WHERE alumno IS NOT NULL;
