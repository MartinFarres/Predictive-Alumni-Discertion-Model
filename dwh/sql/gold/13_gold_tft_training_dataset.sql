-- ============================================================================
-- GOLD: gold_tft_training_dataset
-- FINAL TRAINING DATASET for TFT Model
-- Joins static features with temporal features for complete sequences
-- Each student has multiple rows (one per year) forming a time series
-- ============================================================================

CREATE OR REPLACE TABLE gold.gold_tft_training_dataset AS
SELECT
    -- ===== IDENTIFIERS =====
    tf.alumno_id,
    sf.persona_id,
    tf.anio_academico,
    tf.time_step,
    
    -- ===== STATIC COVARIATES (same for all time steps of a student) =====
    -- Demographics
    sf.sexo,
    sf.nacionalidad,
    DATE_DIFF('year', sf.fecha_nacimiento, MAKE_DATE(tf.anio_academico::BIGINT, 3, 1)) AS edad_al_anio,
    
    -- Academic program
    sf.propuesta_id,
    sf.propuesta_nombre,
    sf.modalidad,
    sf.tipo_ingreso,
    sf.anio_ingreso,
    
    -- Location
    sf.sede_provincia,
    sf.sede_localidad,
    sf.residencia_departamento,
    sf.residencia_localidad,
    sf.origen_departamento,
    sf.origen_localidad,
    
    -- Socioeconomic
    sf.estado_civil,
    sf.cantidad_hijos,
    sf.vive_con,
    sf.cobertura_salud,
    sf.tipo_vivienda,
    sf.trabajo_existe,
    sf.trabajo_hora_sem,
    sf.beca,
    sf.costeos_estudios_familiar,
    sf.costeos_estudios_trabajo,
    sf.costeos_estudios_beca,
    
    -- Technology
    sf.tecnologia_int_casa,
    sf.tecnologia_pc_casa,
    sf.tecnologia_int_movil,
    
    -- Disabilities
    sf.disc_auditiva,
    sf.disc_visual,
    sf.disc_motora,
    
    -- Prior education
    sf.nivel_estudio_previo,
    sf.colegio_secundario_desc,
    
    -- ===== KNOWN FUTURE INPUTS =====
    kf.mes_inicio,
    kf.trimestre_inicio,
    kf.post_pandemia,
    
    -- ===== TIME-VARYING OBSERVED INPUTS =====
    tf.anios_desde_ingreso,
    
    -- Academic performance
    tf.total_evaluaciones,
    tf.materias_cursadas,
    tf.cursadas_intentadas,
    tf.examenes_intentados,
    tf.promedio_notas,
    tf.nota_minima,
    tf.nota_maxima,
    tf.desviacion_notas,
    tf.materias_aprobadas,
    tf.materias_reprobadas,
    tf.materias_ausente,
    tf.tasa_aprobacion,
    tf.tasa_reprobacion,
    tf.tasa_ausentismo,
    tf.creditos_obtenidos,
    
    -- Attendance
    tf.promedio_asistencia,
    tf.total_inasistencias,
    tf.periodos_riesgo_asistencia,
    
    -- Enrollment behavior
    tf.inscripciones_cursada,
    tf.materias_inscriptas,
    tf.examenes_inscriptos,
    tf.materias_examen_inscriptas,
    
    -- Re-inscription
    tf.tuvo_reinscripcion,
    tf.reinscripciones,
    
    -- Status stability
    tf.cambios_estado_anio,
    
    -- Cumulative features
    tf.materias_aprobadas_acum,
    tf.materias_reprobadas_acum,
    tf.creditos_acum,
    tf.promedio_historico,
    tf.tasa_aprobacion_historica,
    
    -- Lag features
    tf.promedio_notas_anterior,
    tf.tasa_aprobacion_anterior,
    tf.tuvo_reinscripcion_anterior,
    
    -- Trend features
    tf.variacion_promedio,
    tf.variacion_tasa_aprobacion,
    tf.variacion_materias,
    
    -- ===== SEQUENCE METADATA =====
    -- Number of time steps for this student
    COUNT(*) OVER (PARTITION BY tf.alumno_id) AS sequence_length,
    
    -- Is this the last observation for the student?
    CASE WHEN tf.time_step = MAX(tf.time_step) OVER (PARTITION BY tf.alumno_id) 
         THEN 1 ELSE 0 END AS is_last_observation,
    
    -- ===== TARGET VARIABLES =====
    tf.dropout_flag,
    tf.dropout_next_year,
    tf.fecha_dropout

FROM gold.gold_tft_temporal_features tf
LEFT JOIN gold.gold_tft_static_features sf ON tf.alumno_id = sf.alumno_id
LEFT JOIN gold.gold_tft_known_future kf ON tf.anio_academico = kf.anio_academico

-- Filter: only students with at least 1 year of data
WHERE tf.anio_academico IS NOT NULL

ORDER BY tf.alumno_id, tf.anio_academico;
