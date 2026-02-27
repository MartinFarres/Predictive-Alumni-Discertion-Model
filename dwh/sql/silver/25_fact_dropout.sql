-- ============================================================================
-- FACT: fact_dropout (Dropout/Loss of Regularity Events)
-- Grain: One row per student-year dropout event
-- This is the TARGET/LABEL for ML models
-- ============================================================================

CREATE OR REPLACE TABLE silver.fact_dropout AS
SELECT
    -- Keys
    pr.alumno AS alumno_id,
    pr.anio_academico,
    
    -- Event details
    pr.perdida_regularidad AS perdida_regularidad_id,
    pr.fecha AS fecha_dropout,
    pr.fecha_control_desde,
    pr.fecha_control_hasta,
    
    -- Target label
    1 AS dropout_flag

FROM bronze.perdida_regularidades pr
WHERE pr.alumno IS NOT NULL;
