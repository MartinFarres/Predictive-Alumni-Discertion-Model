-- ============================================================================
-- DIMENSION: dim_census (Socioeconomic/Census Dimension)
-- Socioeconomic and census data - critical for dropout prediction features
-- ============================================================================

CREATE OR REPLACE TABLE silver.dim_census AS
SELECT
    persona AS persona_id,
    fecha AS fecha_relevamiento,
    
    -- Family & Civil Status
    estado_civil,
    estado_civil_desc,
    union_pareja,
    situacion_padre,
    situacion_madre,
    cantidad_hijos,
    vive_con,
    
    -- Health
    cobertura_salud,
    
    -- Housing
    tipo_vivienda,
    tipo_vivienda_desc,
    
    -- Address during academic period
    periodo_lectivo_localidad,
    periodo_lectivo_localidad_desc,
    periodo_lectivo_departamento,
    periodo_lectivo_departamento_desc,
    periodo_lectivo_codigo_postal,
    
    -- Origin/Permanent Address
    procedencia_localidad,
    procedencia_localidad_desc,
    procedencia_departamento,
    procedencia_departamento_desc,
    procedencia_codigo_postal,
    
    -- Employment & Economic
    trabajo_existe,
    trabajo_existe_desc,
    trabajo_hora_sem,
    beca,
    
    -- Study financing (important risk factors)
    costeos_estudios_familiar,
    costeos_estudios_plan_social,
    costeos_estudios_trabajo,
    costeos_estudios_beca,
    costeos_estudios_otro,
    
    -- Technology access
    tecnologia_int_casa,
    tecnologia_pc_casa,
    tecnologia_int_movil,
    
    -- Activities
    deportes,
    
    -- Disabilities (risk factors)
    disc_auditiva,
    disc_visual,
    disc_motora,
    disc_otra,
    otra_descripcion AS disc_otra_descripcion,
    
    -- Prior Education (important predictor)
    nivel_estudio AS nivel_estudio_previo,
    nivel_estudio_desc AS nivel_estudio_previo_desc,
    institucion AS institucion_previa_id,
    institucion_desc AS institucion_previa_desc,
    colegio AS colegio_secundario_id,
    colegio_desc AS colegio_secundario_desc

FROM bronze.census
WHERE persona IS NOT NULL;
