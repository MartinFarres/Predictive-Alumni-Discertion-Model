-- ============================================================================
-- DIMENSION: dim_fecha (Date Dimension)
-- Standard calendar dimension for time-based analysis
-- ============================================================================

CREATE OR REPLACE TABLE silver.dim_fecha AS
WITH date_spine AS (
    -- Generate dates from 2000 to 2030
    SELECT UNNEST(generate_series(DATE '2000-01-01', DATE '2030-12-31', INTERVAL '1 day'))::DATE AS fecha
)
SELECT
    fecha,
    YEAR(fecha) AS anio,
    MONTH(fecha) AS mes,
    DAY(fecha) AS dia,
    QUARTER(fecha) AS trimestre,
    WEEKOFYEAR(fecha) AS semana,
    DAYOFWEEK(fecha) AS dia_semana,
    DAYNAME(fecha) AS dia_nombre,
    MONTHNAME(fecha) AS mes_nombre,
    -- Academic year: March to February (Argentina)
    CASE 
        WHEN MONTH(fecha) >= 3 THEN YEAR(fecha)
        ELSE YEAR(fecha) - 1
    END AS anio_academico,
    -- Academic semester
    CASE
        WHEN MONTH(fecha) BETWEEN 3 AND 7 THEN 1
        WHEN MONTH(fecha) BETWEEN 8 AND 12 THEN 2
        ELSE 2  -- Jan-Feb belongs to previous year's 2nd semester
    END AS cuatrimestre,
    -- Useful flags
    CASE WHEN DAYOFWEEK(fecha) IN (0, 6) THEN TRUE ELSE FALSE END AS es_fin_semana,
    fecha = DATE_TRUNC('month', fecha) AS es_primer_dia_mes,
    fecha = LAST_DAY(fecha) AS es_ultimo_dia_mes
FROM date_spine;
