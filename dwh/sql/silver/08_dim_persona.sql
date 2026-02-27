-- ============================================================================
-- DIMENSION: dim_persona (Person Demographics Dimension)
-- Demographic information about individuals
-- ============================================================================

CREATE OR REPLACE TABLE silver.dim_persona AS
SELECT
    persona AS persona_id,
    fecha_nacimiento,
    -- Calculate age as of today (for snapshot analysis, use dim_fecha join instead)
    DATE_DIFF('year', fecha_nacimiento, CURRENT_DATE) AS edad_actual,
    sexo,
    localidad_nacimiento,
    localidad_nacimiento_desc,
    nacionalidad,
    nacionalidad_desc
FROM bronze.personas
WHERE persona IS NOT NULL;
