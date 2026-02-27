-- ============================================================================
-- GOLD: gold_tft_temporal_features
-- TIME-VARYING OBSERVED INPUTS for TFT Model
-- Historical features that change over time (grades, attendance, engagement)
-- Grain: One row per student per academic year (time step)
-- ============================================================================

CREATE OR REPLACE TABLE gold.gold_tft_temporal_features AS
WITH 
-- Get all student-year combinations from academic performance
student_years AS (
    SELECT DISTINCT alumno_id, anio_academico
    FROM silver.fact_academic_performance
    WHERE anio_academico IS NOT NULL
    
    UNION
    
    SELECT DISTINCT alumno_id, anio_academico
    FROM silver.fact_reinscription
    WHERE anio_academico IS NOT NULL
    
    UNION
    
    SELECT DISTINCT alumno_id, anio_academico
    FROM silver.fact_dropout
    WHERE anio_academico IS NOT NULL
),

-- Academic performance per year
yearly_academic AS (
    SELECT
        alumno_id,
        anio_academico,
        
        -- Counts
        COUNT(*) AS total_evaluaciones,
        COUNT(DISTINCT elemento_id) AS materias_cursadas,
        COUNT(DISTINCT CASE WHEN tipo_evaluacion = 'CURSADA' THEN elemento_id END) AS cursadas_intentadas,
        COUNT(DISTINCT CASE WHEN tipo_evaluacion = 'EXAMEN' THEN elemento_id END) AS examenes_intentados,
        
        -- Grades
        AVG(TRY_CAST(nota AS DOUBLE)) AS promedio_notas,
        MIN(TRY_CAST(nota AS DOUBLE)) AS nota_minima,
        MAX(TRY_CAST(nota AS DOUBLE)) AS nota_maxima,
        STDDEV(TRY_CAST(nota AS DOUBLE)) AS desviacion_notas,
        MEDIAN(TRY_CAST(nota AS DOUBLE)) AS mediana_notas,
        
        -- Pass/Fail counts
        SUM(aprobado_flag) AS materias_aprobadas,
        SUM(reprobado_flag) AS materias_reprobadas,
        SUM(ausente_flag) AS materias_ausente,
        
        -- Rates
        ROUND(SUM(aprobado_flag)::DOUBLE / NULLIF(COUNT(*), 0), 4) AS tasa_aprobacion,
        ROUND(SUM(reprobado_flag)::DOUBLE / NULLIF(COUNT(*), 0), 4) AS tasa_reprobacion,
        ROUND(SUM(ausente_flag)::DOUBLE / NULLIF(COUNT(*), 0), 4) AS tasa_ausentismo,
        
        -- Attendance
        AVG(pct_asistencia) AS promedio_asistencia_cursadas,
        
        -- Credits
        SUM(creditos) AS creditos_obtenidos
        
    FROM silver.fact_academic_performance
    WHERE anio_academico IS NOT NULL
    GROUP BY alumno_id, anio_academico
),

-- Attendance summary per year
yearly_attendance AS (
    SELECT
        alumno_id,
        anio_academico,
        AVG(porc_asistencia) AS promedio_asistencia,
        SUM(total_inasistencias) AS total_inasistencias,
        SUM(cumple_asistencia_flag) AS periodos_cumple_asistencia,
        SUM(riesgo_asistencia_flag) AS periodos_riesgo_asistencia,
        COUNT(*) AS periodos_con_asistencia
    FROM silver.fact_attendance
    GROUP BY alumno_id, anio_academico
),

-- Course enrollment per year
yearly_enrollment AS (
    SELECT
        alumno_id,
        YEAR(fecha_inscripcion) AS anio_academico,
        COUNT(*) AS inscripciones_cursada,
        COUNT(DISTINCT elemento_id) AS materias_inscriptas
    FROM silver.fact_course_enrollment
    WHERE fecha_inscripcion IS NOT NULL
    GROUP BY alumno_id, YEAR(fecha_inscripcion)
),

-- Exam inscriptions per year
yearly_exams AS (
    SELECT
        alumno_id,
        YEAR(fecha_mesa_examen) AS anio_academico,
        COUNT(*) AS examenes_inscriptos,
        COUNT(DISTINCT elemento_id) AS materias_examen_inscriptas,
        COUNT(DISTINCT instancia_id) AS tipos_instancia_usados
    FROM silver.fact_exam_inscription
    WHERE fecha_mesa_examen IS NOT NULL
    GROUP BY alumno_id, YEAR(fecha_mesa_examen)
),

-- Reinscription per year
yearly_reinscription AS (
    SELECT
        alumno_id,
        anio_academico,
        COUNT(*) AS reinscripciones,
        MIN(fecha_reinscripcion) AS primera_reinscripcion,
        MAX(fecha_reinscripcion) AS ultima_reinscripcion,
        1 AS tuvo_reinscripcion
    FROM silver.fact_reinscription
    GROUP BY alumno_id, anio_academico
),

-- Status changes per year
yearly_status_changes AS (
    SELECT
        alumno_id,
        YEAR(fecha_cambio) AS anio_academico,
        COUNT(*) AS cambios_estado_anio
    FROM silver.fact_student_status_history
    GROUP BY alumno_id, YEAR(fecha_cambio)
),

-- Dropout events (TARGET)
dropout_events AS (
    SELECT
        alumno_id,
        anio_academico,
        1 AS dropout_flag,
        fecha_dropout
    FROM silver.fact_dropout
)

SELECT
    -- ===== IDENTIFIERS & TIME =====
    sy.alumno_id,
    sy.anio_academico,
    
    -- Time step index (for sequence ordering)
    ROW_NUMBER() OVER (PARTITION BY sy.alumno_id ORDER BY sy.anio_academico) AS time_step,
    
    -- Years since enrollment (temporal feature)
    sy.anio_academico - ds.anio_ingreso AS anios_desde_ingreso,
    
    -- ===== ACADEMIC PERFORMANCE (OBSERVED) =====
    COALESCE(ya.total_evaluaciones, 0) AS total_evaluaciones,
    COALESCE(ya.materias_cursadas, 0) AS materias_cursadas,
    COALESCE(ya.cursadas_intentadas, 0) AS cursadas_intentadas,
    COALESCE(ya.examenes_intentados, 0) AS examenes_intentados,
    
    ya.promedio_notas,
    ya.nota_minima,
    ya.nota_maxima,
    ya.desviacion_notas,
    ya.mediana_notas,
    
    COALESCE(ya.materias_aprobadas, 0) AS materias_aprobadas,
    COALESCE(ya.materias_reprobadas, 0) AS materias_reprobadas,
    COALESCE(ya.materias_ausente, 0) AS materias_ausente,
    
    COALESCE(ya.tasa_aprobacion, 0) AS tasa_aprobacion,
    COALESCE(ya.tasa_reprobacion, 0) AS tasa_reprobacion,
    COALESCE(ya.tasa_ausentismo, 0) AS tasa_ausentismo,
    
    ya.promedio_asistencia_cursadas,
    COALESCE(ya.creditos_obtenidos, 0) AS creditos_obtenidos,
    
    -- ===== ATTENDANCE (OBSERVED) =====
    yat.promedio_asistencia,
    COALESCE(yat.total_inasistencias, 0) AS total_inasistencias,
    COALESCE(yat.periodos_cumple_asistencia, 0) AS periodos_cumple_asistencia,
    COALESCE(yat.periodos_riesgo_asistencia, 0) AS periodos_riesgo_asistencia,
    
    -- ===== ENROLLMENT BEHAVIOR (OBSERVED) =====
    COALESCE(ye.inscripciones_cursada, 0) AS inscripciones_cursada,
    COALESCE(ye.materias_inscriptas, 0) AS materias_inscriptas,
    COALESCE(yex.examenes_inscriptos, 0) AS examenes_inscriptos,
    COALESCE(yex.materias_examen_inscriptas, 0) AS materias_examen_inscriptas,
    
    -- ===== RE-INSCRIPTION (OBSERVED) =====
    COALESCE(yr.tuvo_reinscripcion, 0) AS tuvo_reinscripcion,
    COALESCE(yr.reinscripciones, 0) AS reinscripciones,
    yr.primera_reinscripcion,
    yr.ultima_reinscripcion,
    
    -- ===== STATUS STABILITY (OBSERVED) =====
    COALESCE(ysc.cambios_estado_anio, 0) AS cambios_estado_anio,
    
    -- ===== CUMULATIVE FEATURES (computed over time) =====
    SUM(COALESCE(ya.materias_aprobadas, 0)) OVER w_past AS materias_aprobadas_acum,
    SUM(COALESCE(ya.materias_reprobadas, 0)) OVER w_past AS materias_reprobadas_acum,
    SUM(COALESCE(ya.creditos_obtenidos, 0)) OVER w_past AS creditos_acum,
    AVG(ya.promedio_notas) OVER w_past AS promedio_historico,
    AVG(ya.tasa_aprobacion) OVER w_past AS tasa_aprobacion_historica,
    
    -- ===== LAG FEATURES (previous year values) =====
    LAG(ya.promedio_notas, 1) OVER w_student AS promedio_notas_anterior,
    LAG(ya.tasa_aprobacion, 1) OVER w_student AS tasa_aprobacion_anterior,
    LAG(ya.materias_aprobadas, 1) OVER w_student AS materias_aprobadas_anterior,
    LAG(yr.tuvo_reinscripcion, 1) OVER w_student AS tuvo_reinscripcion_anterior,
    
    -- ===== TREND FEATURES (year-over-year change) =====
    ya.promedio_notas - LAG(ya.promedio_notas, 1) OVER w_student AS variacion_promedio,
    ya.tasa_aprobacion - LAG(ya.tasa_aprobacion, 1) OVER w_student AS variacion_tasa_aprobacion,
    ya.materias_cursadas - LAG(ya.materias_cursadas, 1) OVER w_student AS variacion_materias,
    
    -- ===== TARGET VARIABLE =====
    COALESCE(de.dropout_flag, 0) AS dropout_flag,
    de.fecha_dropout,
    
    -- ===== NEXT YEAR TARGET (for prediction) =====
    LEAD(COALESCE(de.dropout_flag, 0), 1) OVER w_student AS dropout_next_year

FROM student_years sy
LEFT JOIN silver.dim_student ds ON sy.alumno_id = ds.alumno_id
LEFT JOIN yearly_academic ya ON sy.alumno_id = ya.alumno_id AND sy.anio_academico = ya.anio_academico
LEFT JOIN yearly_attendance yat ON sy.alumno_id = yat.alumno_id AND sy.anio_academico = yat.anio_academico
LEFT JOIN yearly_enrollment ye ON sy.alumno_id = ye.alumno_id AND sy.anio_academico = ye.anio_academico
LEFT JOIN yearly_exams yex ON sy.alumno_id = yex.alumno_id AND sy.anio_academico = yex.anio_academico
LEFT JOIN yearly_reinscription yr ON sy.alumno_id = yr.alumno_id AND sy.anio_academico = yr.anio_academico
LEFT JOIN yearly_status_changes ysc ON sy.alumno_id = ysc.alumno_id AND sy.anio_academico = ysc.anio_academico
LEFT JOIN dropout_events de ON sy.alumno_id = de.alumno_id AND sy.anio_academico = de.anio_academico

WINDOW 
    w_student AS (PARTITION BY sy.alumno_id ORDER BY sy.anio_academico),
    w_past AS (PARTITION BY sy.alumno_id ORDER BY sy.anio_academico ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)

ORDER BY sy.alumno_id, sy.anio_academico;
