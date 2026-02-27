-- ============================================================================
-- DIMENSION: dim_elemento (Course/Subject Dimension)
-- Master catalog of academic courses and subjects
-- ============================================================================

CREATE OR REPLACE TABLE silver.dim_elemento AS
SELECT DISTINCT
    elemento AS elemento_id,
    materia_codigo,
    materia_nombre
FROM bronze.elementos
WHERE elemento IS NOT NULL;
