-- ============================================================================
-- FACT: fact_course_enrollment (Course Inscriptions)
-- Grain: One row per student-course-period enrollment
-- ============================================================================

CREATE OR REPLACE TABLE silver.fact_course_enrollment AS
SELECT
    -- Keys
    ci.alumno AS alumno_id,
    ci.elemento_id,
    ci.plan_version_id,
    
    -- Enrollment details
    ci.inscripcion_id,
    ci.fecha_inscripcion,
    ci.estado_inscripcion,
    ci.periodo_lectivo,
    
    -- Descriptive (denormalized for convenience)
    ci.catedra_cod,
    ci.catedra_nombre,
    
    -- Metrics
    1 AS enrollment_count

FROM bronze.course_inscriptions ci
WHERE ci.alumno IS NOT NULL;
