-- ============================================================================
-- GOLD: gold_student_engagement
-- Aggregated engagement metrics (attendance, reinscription, exams) per student
-- Features for ML dropout prediction model
-- ============================================================================

CREATE OR REPLACE TABLE gold.mart_student_engagement AS
WITH attendance_summary AS (
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
reinscription_summary AS (
    SELECT
        alumno_id,
        anio_academico,
        COUNT(*) AS reinscripciones_anio,
        MIN(fecha_reinscripcion) AS primera_reinscripcion,
        MAX(fecha_reinscripcion) AS ultima_reinscripcion
    FROM silver.fact_reinscription
    GROUP BY alumno_id, anio_academico
),
exam_summary AS (
    SELECT
        alumno_id,
        YEAR(fecha_mesa_examen) AS anio_academico,
        COUNT(*) AS examenes_inscriptos,
        COUNT(DISTINCT elemento_id) AS materias_examen
    FROM silver.fact_exam_inscription
    WHERE fecha_mesa_examen IS NOT NULL
    GROUP BY alumno_id, YEAR(fecha_mesa_examen)
),
enrollment_summary AS (
    SELECT
        alumno_id,
        COUNT(*) AS total_inscripciones_cursada,
        COUNT(DISTINCT elemento_id) AS total_materias_inscriptas
    FROM silver.fact_course_enrollment
    GROUP BY alumno_id
)
SELECT
    s.alumno_id,
    COALESCE(a.anio_academico, r.anio_academico, e.anio_academico) AS anio_academico,
    
    -- Attendance features
    a.promedio_asistencia,
    a.total_inasistencias,
    a.periodos_cumple_asistencia,
    a.periodos_riesgo_asistencia,
    
    -- Reinscription features
    COALESCE(r.reinscripciones_anio, 0) AS reinscripciones_anio,
    r.primera_reinscripcion,
    r.ultima_reinscripcion,
    
    -- Exam engagement
    COALESCE(e.examenes_inscriptos, 0) AS examenes_inscriptos,
    COALESCE(e.materias_examen, 0) AS materias_examen,
    
    -- Overall enrollment
    en.total_inscripciones_cursada,
    en.total_materias_inscriptas,
    
    -- Engagement score (simple weighted average)
    ROUND((
        COALESCE(a.promedio_asistencia, 0) * 0.4 +
        COALESCE(r.reinscripciones_anio, 0) * 20 +
        COALESCE(e.examenes_inscriptos, 0) * 5
    ), 2) AS engagement_score

FROM silver.dim_student s
LEFT JOIN attendance_summary a ON s.alumno_id = a.alumno_id
LEFT JOIN reinscription_summary r ON s.alumno_id = r.alumno_id 
    AND (a.anio_academico = r.anio_academico OR a.anio_academico IS NULL)
LEFT JOIN exam_summary e ON s.alumno_id = e.alumno_id 
    AND (COALESCE(a.anio_academico, r.anio_academico) = e.anio_academico OR (a.anio_academico IS NULL AND r.anio_academico IS NULL))
LEFT JOIN enrollment_summary en ON s.alumno_id = en.alumno_id
WHERE COALESCE(a.anio_academico, r.anio_academico, e.anio_academico) IS NOT NULL;
