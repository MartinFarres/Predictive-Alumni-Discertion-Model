-- ============================================================================
-- GOLD: gold_student_academic_summary
-- Aggregated academic performance metrics per student per year
-- Features for ML dropout prediction model
-- ============================================================================

CREATE OR REPLACE TABLE gold.mart_student_academic_summary AS
WITH yearly_performance AS (
    SELECT
        alumno_id,
        anio_academico,
        
        -- Course counts
        COUNT(*) AS total_evaluaciones,
        COUNT(DISTINCT elemento_id) AS materias_cursadas,
        
        -- Grade statistics (nota is VARCHAR, try to cast numeric values)
        AVG(TRY_CAST(nota AS DOUBLE)) AS promedio_notas,
        MIN(TRY_CAST(nota AS DOUBLE)) AS nota_minima,
        MAX(TRY_CAST(nota AS DOUBLE)) AS nota_maxima,
        STDDEV(TRY_CAST(nota AS DOUBLE)) AS desviacion_notas,
        
        -- Pass/Fail rates
        SUM(aprobado_flag) AS materias_aprobadas,
        SUM(reprobado_flag) AS materias_reprobadas,
        SUM(ausente_flag) AS materias_ausente,
        
        -- Ratios
        ROUND(SUM(aprobado_flag)::FLOAT / NULLIF(COUNT(*), 0), 3) AS tasa_aprobacion,
        ROUND(SUM(reprobado_flag)::FLOAT / NULLIF(COUNT(*), 0), 3) AS tasa_reprobacion,
        ROUND(SUM(ausente_flag)::FLOAT / NULLIF(COUNT(*), 0), 3) AS tasa_ausentismo
        
    FROM silver.fact_academic_performance
    WHERE anio_academico IS NOT NULL
    GROUP BY alumno_id, anio_academico
),
cumulative_performance AS (
    SELECT
        alumno_id,
        anio_academico,
        
        -- Cumulative metrics (all years up to current)
        SUM(total_evaluaciones) OVER w AS total_evaluaciones_acum,
        SUM(materias_aprobadas) OVER w AS materias_aprobadas_acum,
        SUM(materias_reprobadas) OVER w AS materias_reprobadas_acum,
        AVG(promedio_notas) OVER w AS promedio_historico,
        AVG(tasa_aprobacion) OVER w AS tasa_aprobacion_historica
        
    FROM yearly_performance
    WINDOW w AS (PARTITION BY alumno_id ORDER BY anio_academico ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
)
SELECT
    yp.*,
    cp.total_evaluaciones_acum,
    cp.materias_aprobadas_acum,
    cp.materias_reprobadas_acum,
    cp.promedio_historico,
    cp.tasa_aprobacion_historica,
    
    -- Year-over-year change
    yp.promedio_notas - LAG(yp.promedio_notas) OVER (PARTITION BY yp.alumno_id ORDER BY yp.anio_academico) AS variacion_promedio,
    yp.tasa_aprobacion - LAG(yp.tasa_aprobacion) OVER (PARTITION BY yp.alumno_id ORDER BY yp.anio_academico) AS variacion_tasa_aprobacion

FROM yearly_performance yp
JOIN cumulative_performance cp 
    ON yp.alumno_id = cp.alumno_id 
    AND yp.anio_academico = cp.anio_academico
ORDER BY yp.alumno_id, yp.anio_academico;
