-- ============================================================================
-- DIMENSION: dim_propuesta (Academic Program/Career Dimension)
-- Master data for academic programs/careers
-- ============================================================================

CREATE OR REPLACE TABLE silver.dim_propuesta AS
SELECT DISTINCT
    propuesta AS propuesta_id,
    propuesta_nombre,
    propuesta_codigo
FROM bronze.students
WHERE propuesta IS NOT NULL;
