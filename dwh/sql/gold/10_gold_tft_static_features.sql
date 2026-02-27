-- ============================================================================
-- GOLD: gold_tft_static_features
-- STATIC COVARIATES for TFT Model (unchanging per student)
-- These are student characteristics that don't change over time
-- ============================================================================

CREATE OR REPLACE TABLE gold.gold_tft_static_features AS
SELECT
    -- Identifiers
    ds.alumno_id,
    ds.persona_id,
    
    -- ===== STUDENT CHARACTERISTICS (STATIC) =====
    ds.propuesta_id,
    ds.propuesta_nombre,
    ds.plan_version_id,
    ds.ubicacion_id,
    ds.modalidad,
    ds.tipo_ingreso,
    ds.anio_ingreso,
    ds.fecha_ingreso,
    
    -- ===== DEMOGRAPHICS (STATIC) =====
    dp.sexo,
    dp.fecha_nacimiento,
    dp.nacionalidad,
    dp.nacionalidad_desc,
    dp.localidad_nacimiento,
    dp.localidad_nacimiento_desc,
    
    -- ===== LOCATION: INSTITUTIONAL (STATIC) =====
    du.see_nombre AS sede_nombre,
    du.see_localidad AS sede_localidad,
    du.see_dpto AS sede_departamento,
    du.see_provincia AS sede_provincia,
    du.see_codigo_postal AS sede_codigo_postal,
    
    -- ===== SOCIOECONOMIC/CENSUS (SEMI-STATIC - from latest census) =====
    dc.fecha_relevamiento AS fecha_censo,
    dc.estado_civil,
    dc.union_pareja,
    dc.cantidad_hijos,
    dc.vive_con,
    dc.situacion_padre,
    dc.situacion_madre,
    dc.cobertura_salud,
    dc.tipo_vivienda,
    
    -- Location: Residence during academic period
    dc.periodo_lectivo_localidad AS residencia_localidad,
    dc.periodo_lectivo_localidad_desc AS residencia_localidad_desc,
    dc.periodo_lectivo_departamento AS residencia_departamento,
    dc.periodo_lectivo_departamento_desc AS residencia_departamento_desc,
    dc.periodo_lectivo_codigo_postal AS residencia_codigo_postal,
    
    -- Location: Origin/Permanent
    dc.procedencia_localidad AS origen_localidad,
    dc.procedencia_localidad_desc AS origen_localidad_desc,
    dc.procedencia_departamento AS origen_departamento,
    dc.procedencia_departamento_desc AS origen_departamento_desc,
    dc.procedencia_codigo_postal AS origen_codigo_postal,
    
    -- Employment (initial situation)
    dc.trabajo_existe,
    dc.trabajo_hora_sem,
    dc.beca,
    
    -- Study financing
    dc.costeos_estudios_familiar,
    dc.costeos_estudios_plan_social,
    dc.costeos_estudios_trabajo,
    dc.costeos_estudios_beca,
    dc.costeos_estudios_otro,
    
    -- Technology access
    dc.tecnologia_int_casa,
    dc.tecnologia_pc_casa,
    dc.tecnologia_int_movil,
    
    -- Disabilities
    dc.disc_auditiva,
    dc.disc_visual,
    dc.disc_motora,
    dc.disc_otra,
    
    -- Prior education (important predictor)
    dc.nivel_estudio_previo,
    dc.nivel_estudio_previo_desc,
    dc.colegio_secundario_id,
    dc.colegio_secundario_desc,
    dc.institucion_previa_id,
    dc.institucion_previa_desc,
    
    -- Sports/Activities
    dc.deportes

FROM silver.dim_student ds
LEFT JOIN silver.dim_persona dp ON ds.persona_id = dp.persona_id
LEFT JOIN silver.dim_ubicacion du ON ds.ubicacion_id = du.ubicacion_id
LEFT JOIN silver.dim_census dc ON ds.persona_id = dc.persona_id;
