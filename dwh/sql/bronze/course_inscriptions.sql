SELECT
    sic.alumno,
    sic.inscripcion AS inscripcion_id,
    se.elemento AS elemento_id,
    se.codigo AS catedra_cod,
    se.nombre AS catedra_nombre,
    sp.nombre AS periodo_lectivo,
    sic.plan_version AS plan_version_id,
    spv.nombre AS plan_version_desc,
    sic.fecha_inscripcion,
    sic.estado AS estado_inscripcion
FROM negocio.sga_insc_cursada sic
LEFT JOIN negocio.sga_comisiones sc ON sic.comision = sc.comision
LEFT JOIN negocio.sga_elementos se ON sc.elemento = se.elemento
LEFT JOIN negocio.sga_periodos_lectivos spl ON sc.periodo_lectivo = spl.periodo_lectivo
LEFT JOIN negocio.sga_periodos sp ON spl.periodo = sp.periodo
LEFT JOIN negocio.sga_planes_versiones spv ON sic.plan_version = spv.plan_version;
