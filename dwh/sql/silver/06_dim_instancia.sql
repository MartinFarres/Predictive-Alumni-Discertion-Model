-- ============================================================================
-- DIMENSION: dim_instancia (Exam Instance Type Dimension)
-- Types of exam instances (regular, makeup, etc.)
-- ============================================================================

CREATE OR REPLACE TABLE silver.dim_instancia AS
SELECT DISTINCT
    instancia AS instancia_id,
    instancia_nombre
FROM bronze.instancias
WHERE instancia IS NOT NULL;
