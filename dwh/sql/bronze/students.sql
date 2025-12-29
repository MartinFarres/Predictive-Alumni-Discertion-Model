SELECT 
    a.alumno,
    a.persona,
    -- Propuesta y detalles
    a.propuesta,
    sp.nombre AS propuesta_nombre,
    sp.codigo AS propuesta_codigo,
    -- Plan versión (id y nombre)
    a.plan_version AS plan_version_id,
    spv.nombre AS plan_version,
    -- Ubicación y detalles SEE
    a.ubicacion,
    su.nombre AS see_nombre,
    su.calle AS see_calle,
    su.numero AS see_numero,
    su.codigo_postal AS see_codigo_postal,
    iai.nombre AS see_institucion,
    iai.institucion_nombre AS see_institucion_p,
    ml.nombre AS see_localidad,
    mdp2.nombre AS see_dpto,
    mp.nombre AS see_provincia,
    -- Otras banderas de alumno
    a.modalidad,
    a.regular,
    -- Ingreso
    pa.fecha_inscripcion AS fecha_ingreso,
    pa.tipo_ingreso
FROM negocio.sga_alumnos AS a
LEFT JOIN negocio.sga_propuestas_aspira AS pa 
    ON a.persona = pa.persona 
    AND a.propuesta = pa.propuesta
LEFT JOIN negocio.sga_situacion_aspirante AS sa 
    ON pa.situacion_asp = sa.situacion_asp
-- Joins para propuesta y plan
LEFT JOIN negocio.sga_propuestas sp ON a.propuesta = sp.propuesta
LEFT JOIN negocio.sga_planes_versiones spv ON a.plan_version = spv.plan_version
-- Joins para ubicación (SEE)
LEFT JOIN negocio.sga_ubicaciones su ON a.ubicacion = su.ubicacion
LEFT JOIN negocio.int_arau_instituciones iai ON su.institucion_araucano = iai.institucion_araucano
LEFT JOIN negocio.mug_localidades ml ON su.localidad = ml.localidad
LEFT JOIN negocio.mug_dptos_partidos mdp2 ON ml.dpto_partido = mdp2.dpto_partido
LEFT JOIN negocio.mug_provincias mp ON mdp2.provincia = mp.provincia
WHERE sa.resultado_asp IN ('A', 'P') OR sa.resultado_asp IS NULL;
