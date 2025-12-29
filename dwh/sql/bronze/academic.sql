SELECT
    sc.alumno,
    sp.anio_academico,
    spl.periodo_lectivo,
    scom.elemento, -- This is the course
    -- Convert nota_cursada to numeric, handling NULL and non-numeric values
    CASE 
        WHEN sedc.nota_cursada ~ '^[0-9]+\.?[0-9]*$' 
        THEN CAST(sedc.nota_cursada AS numeric)
        ELSE NULL 
    END AS nota_cursada,
    sedc.resultado_cursada,
    sedc.fecha_regular AS fecha_nota
FROM negocio.sga_insc_cursada sc
INNER JOIN negocio.sga_comisiones scom ON sc.comision = scom.comision
INNER JOIN negocio.sga_periodos_lectivos spl ON scom.periodo_lectivo = spl.periodo_lectivo
INNER JOIN negocio.sga_periodos sp ON spl.periodo = sp.periodo
LEFT JOIN negocio.sga_evaluaciones sev ON sev.entidad = scom.comision
LEFT JOIN negocio.sga_eval_detalle_cursadas sedc 
    ON sedc.evaluacion = sev.evaluacion AND sedc.alumno = sc.alumno
WHERE sp.anio_academico IS NOT NULL;
