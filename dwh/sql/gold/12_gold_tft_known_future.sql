-- ============================================================================
-- GOLD: gold_tft_known_future
-- KNOWN FUTURE INPUTS for TFT Model
-- These are features that are known in advance (calendar, institutional events)
-- Grain: One row per academic year
-- ============================================================================

CREATE OR REPLACE TABLE gold.gold_tft_known_future AS
SELECT
    dp.anio_academico,
    dp.fecha_inicio,
    dp.fecha_fin,
    dp.periodo_label,
    dp.anio_relativo,
    
    -- Calendar features (known in advance)
    MONTH(dp.fecha_inicio) AS mes_inicio,
    QUARTER(dp.fecha_inicio) AS trimestre_inicio,
    
    -- Relative position in dataset
    dp.anio_relativo AS time_index,
    
    -- Could add institutional events here if available:
    -- holidays, exam periods, enrollment deadlines, etc.
    
    -- Flags for specific years (if relevant institutional changes occurred)
    CASE WHEN dp.anio_academico >= 2020 THEN 1 ELSE 0 END AS post_pandemia

FROM silver.dim_periodo dp
ORDER BY dp.anio_academico;
