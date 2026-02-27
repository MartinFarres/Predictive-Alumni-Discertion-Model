-- ============================================================================
-- DIMENSION: dim_periodo (Academic Period Dimension)
-- Academic years and periods for enrollment/performance analysis
-- ============================================================================

CREATE OR REPLACE TABLE silver.dim_periodo AS
WITH academic_years AS (
    -- Extract distinct academic years from various bronze tables
    SELECT DISTINCT anio_academico 
    FROM bronze.academic
    WHERE anio_academico IS NOT NULL
    
    UNION
    
    SELECT DISTINCT anio_academico 
    FROM bronze.reinscripciones
    WHERE anio_academico IS NOT NULL
    
    UNION
    
    SELECT DISTINCT anio_academico 
    FROM bronze.dropout
    WHERE anio_academico IS NOT NULL
    
    UNION
    
    SELECT DISTINCT anio_academico 
    FROM bronze.attendance
    WHERE anio_academico IS NOT NULL
)
SELECT
    anio_academico,
    -- Calculate period boundaries (Argentina academic calendar)
    MAKE_DATE(anio_academico::BIGINT, 3, 1) AS fecha_inicio,
    MAKE_DATE((anio_academico + 1)::BIGINT, 2, 28) AS fecha_fin,
    -- Labels
    CONCAT(anio_academico, '-', anio_academico + 1) AS periodo_label,
    -- Relative position (useful for ML features)
    anio_academico - (SELECT MIN(anio_academico) FROM academic_years) AS anio_relativo
FROM academic_years
ORDER BY anio_academico;
