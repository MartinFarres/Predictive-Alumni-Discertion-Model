-- ============================================================================
-- DIMENSION: dim_student (Student Master Dimension)
-- Core student dimension linking to persona, propuesta, faculty, and enrollment info
-- ============================================================================

CREATE OR REPLACE TABLE silver.dim_student AS
SELECT
    s.alumno AS alumno_id,
    s.persona AS persona_id,
    
    -- Academic Program
    s.propuesta AS propuesta_id,
    s.propuesta_nombre,
    s.plan_version_id,
    s.plan_version,
    
    -- Faculty / Delegation
    f.facultad_id,
    f.facultad_nombre,
    f.universidad_nombre,
    f.tipo_sede,
    f.ubicacion_sede,
    
    -- Location
    s.ubicacion AS ubicacion_id,
    s.see_provincia AS sede_provincia,
    
    -- Student Status
    s.modalidad,
    s.regular AS es_regular,
    
    -- Enrollment Info
    s.fecha_ingreso,
    s.tipo_ingreso,
    YEAR(s.fecha_ingreso) AS anio_ingreso,
    
    -- Derived: Years since enrollment (as of current date)
    DATE_DIFF('year', s.fecha_ingreso, CURRENT_DATE) AS antiguedad_anios

FROM bronze.students s
LEFT JOIN silver.dim_facultad f ON s.see_institucion = f.facultad_nombre
WHERE s.alumno IS NOT NULL;
