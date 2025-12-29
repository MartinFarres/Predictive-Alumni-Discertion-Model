SELECT
    sca.alumno,
    sp.anio_academico,
    sca.porc_asistencia,
    sca.total_inasistencias
FROM negocio.sga_clases_asistencia_acum sca
INNER JOIN negocio.sga_comisiones sc ON sca.comision = sc.comision
INNER JOIN negocio.sga_periodos_lectivos spl ON sc.periodo_lectivo = spl.periodo_lectivo
INNER JOIN negocio.sga_periodos sp ON spl.periodo = sp.periodo;
