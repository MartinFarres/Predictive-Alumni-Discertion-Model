SELECT
    sie.alumno,
    sie.inscripcion AS inscripcion_id,
    se.elemento AS elemento_id,
    se.codigo AS catedra_cod,
    se.nombre AS catedra_nombre,
    slm.fecha AS fecha_mesa_examen,
    sie.instancia AS instancia_id,
    sin.nombre AS instancia_desc,
    sie.plan_version AS plan_version_id,
    spv.nombre AS plan_version_desc
FROM negocio.sga_insc_examen sie
LEFT JOIN negocio.sga_llamados_mesa slm ON sie.llamado_mesa = slm.llamado_mesa
LEFT JOIN negocio.sga_mesas_examen sme ON slm.mesa_examen = sme.mesa_examen
LEFT JOIN negocio.sga_elementos se ON sme.elemento = se.elemento
LEFT JOIN negocio.sga_instancias sin ON sie.instancia = sin.instancia
LEFT JOIN negocio.sga_planes_versiones spv ON sie.plan_version = spv.plan_version;
