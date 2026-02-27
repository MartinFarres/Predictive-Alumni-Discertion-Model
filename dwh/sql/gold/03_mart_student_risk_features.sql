-- ============================================================================
-- GOLD: gold_student_risk_features
-- Combined feature table for ML dropout prediction model
-- Joins academic, engagement, demographic, and socioeconomic features
-- ============================================================================

CREATE OR REPLACE TABLE gold.mart_student_risk_features AS
WITH dropout_labels AS (
    -- Get dropout events (target variable)
    SELECT
        alumno_id,
        anio_academico,
        1 AS dropout_label,
        fecha_dropout
    FROM silver.fact_dropout
),
status_changes AS (
    -- Count status changes as instability indicator
    SELECT
        alumno_id,
        COUNT(*) AS total_cambios_estado,
        MAX(nro_cambio) AS ultimo_nro_cambio
    FROM silver.fact_student_status_history
    GROUP BY alumno_id
)
SELECT
    -- Student identifiers
    ds.alumno_id,
    ds.persona_id,
    ap.anio_academico,
    
    -- Student characteristics
    ds.propuesta_id,
    ds.modalidad,
    ds.es_regular,
    ds.anio_ingreso,
    ds.antiguedad_anios,
    ds.tipo_ingreso,
    
    -- Faculty / Delegation
    ds.facultad_id,
    ds.facultad_nombre,
    
    -- Demographics
    dp.sexo,
    dp.edad_actual,
    dp.nacionalidad_desc,
    
    -- Socioeconomic (census data)
    dc.estado_civil,
    dc.cantidad_hijos,
    dc.trabajo_existe,
    dc.trabajo_hora_sem,
    dc.beca,
    dc.costeos_estudios_familiar,
    dc.costeos_estudios_trabajo,
    dc.costeos_estudios_beca,
    dc.tecnologia_int_casa,
    dc.tecnologia_pc_casa,
    dc.nivel_estudio_previo,
    dc.disc_auditiva,
    dc.disc_visual,
    dc.disc_motora,
    
    -- Academic performance features
    ap.materias_cursadas,
    ap.promedio_notas,
    ap.nota_minima,
    ap.desviacion_notas,
    ap.materias_aprobadas,
    ap.materias_reprobadas,
    ap.tasa_aprobacion,
    ap.tasa_reprobacion,
    ap.tasa_ausentismo,
    ap.promedio_historico,
    ap.tasa_aprobacion_historica,
    ap.variacion_promedio,
    ap.variacion_tasa_aprobacion,
    
    -- Engagement features
    eg.promedio_asistencia,
    eg.total_inasistencias,
    eg.periodos_riesgo_asistencia,
    eg.reinscripciones_anio,
    eg.examenes_inscriptos,
    eg.engagement_score,
    
    -- Status instability
    COALESCE(sc.total_cambios_estado, 0) AS total_cambios_estado,
    
    -- Risk indicators (derived)
    CASE WHEN ap.tasa_aprobacion < 0.5 THEN 1 ELSE 0 END AS riesgo_academico,
    CASE WHEN eg.promedio_asistencia < 60 THEN 1 ELSE 0 END AS riesgo_asistencia,
    CASE WHEN eg.reinscripciones_anio = 0 THEN 1 ELSE 0 END AS riesgo_no_reinscripcion,
    CASE WHEN dc.trabajo_hora_sem > 30 THEN 1 ELSE 0 END AS riesgo_trabajo_excesivo,
    
    -- Combined risk score (simple heuristic)
    (
        CASE WHEN ap.tasa_aprobacion < 0.5 THEN 2 ELSE 0 END +
        CASE WHEN eg.promedio_asistencia < 60 THEN 2 ELSE 0 END +
        CASE WHEN eg.reinscripciones_anio = 0 THEN 3 ELSE 0 END +
        CASE WHEN dc.trabajo_hora_sem > 30 THEN 1 ELSE 0 END +
        CASE WHEN ap.variacion_tasa_aprobacion < -0.2 THEN 2 ELSE 0 END +
        CASE WHEN sc.total_cambios_estado > 2 THEN 1 ELSE 0 END
    ) AS risk_score_heuristic,
    
    -- TARGET VARIABLE
    COALESCE(dl.dropout_label, 0) AS dropout_label,
    dl.fecha_dropout

FROM silver.dim_student ds
-- Join academic performance (yearly)
LEFT JOIN gold.mart_student_academic_summary ap 
    ON ds.alumno_id = ap.alumno_id
-- Join engagement metrics
LEFT JOIN gold.mart_student_engagement eg 
    ON ds.alumno_id = eg.alumno_id 
    AND ap.anio_academico = eg.anio_academico
-- Join demographics
LEFT JOIN silver.dim_persona dp 
    ON ds.persona_id = dp.persona_id
-- Join census/socioeconomic data
LEFT JOIN silver.dim_census dc 
    ON ds.persona_id = dc.persona_id
-- Join status changes
LEFT JOIN status_changes sc 
    ON ds.alumno_id = sc.alumno_id
-- Join dropout labels (target)
LEFT JOIN dropout_labels dl 
    ON ds.alumno_id = dl.alumno_id 
    AND ap.anio_academico = dl.anio_academico

WHERE ap.anio_academico IS NOT NULL
ORDER BY ds.alumno_id, ap.anio_academico;
