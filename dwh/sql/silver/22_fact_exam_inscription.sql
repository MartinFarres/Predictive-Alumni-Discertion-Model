-- ============================================================================
-- FACT: fact_exam_inscription (Exam Inscriptions)
-- Grain: One row per student-exam-instance
-- ============================================================================

CREATE OR REPLACE TABLE silver.fact_exam_inscription AS
SELECT
    -- Keys
    ei.alumno AS alumno_id,
    ei.elemento_id,
    ei.instancia_id,
    ei.plan_version_id,
    
    -- Exam details
    ei.inscripcion_id,
    ei.fecha_mesa_examen,
    ei.instancia_desc,
    
    -- Descriptive
    ei.catedra_cod,
    ei.catedra_nombre,
    
    -- Metrics
    1 AS exam_inscription_count

FROM bronze.exam_inscriptions ei
WHERE ei.alumno IS NOT NULL;
