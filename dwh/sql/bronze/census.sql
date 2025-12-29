-- Información censal + datos personales para features socioeconómicos y domicilio (periodo lectivo)
-- Nota: Se asume que las columnas existen en mdp_datos_personales. Ajustar nombres si difieren en el schema real.
WITH RankedCensus AS (
    SELECT
        mpc.persona,
        mpc.fecha_relevamiento AS fecha,
        -- Estado civil y unión de hecho / pareja
        mdp.estado_civil,
        mec.descripcion AS estado_civil_desc,
        mdp.unido_hecho AS union_pareja,
        -- Situación de los padres
        mdp.situacion_padre,
        mdp.situacion_madre,
        -- Cobertura de salud
        mdp.cobertura_salud,
        -- Otros datos personales ya presentes
        mdp.cantidad_hijos,
        mdp.tipo_vivienda,
        mtv.descripcion AS tipo_vivienda_desc,
        mdp.vive_con,
        -- Domicilio en periodo lectivo (reemplaza procedencia_*)
        mdp.periodo_lectivo_calle,
        mdp.periodo_lectivo_numero,
        mdp.periodo_lectivo_departamento,
        pld.nombre AS periodo_lectivo_departamento_desc,
        mdp.periodo_lectivo_localidad,
        pll.nombre AS periodo_lectivo_localidad_desc,
        COALESCE(
            CASE
                WHEN TRIM(mdp.periodo_lectivo_departamento::text) ~ '^[0-9]+$'
                THEN TRIM(mdp.periodo_lectivo_departamento::text)::bigint
            END,
            pll.dpto_partido
        ) AS periodo_lectivo_departamento_resolved,
        mdp.periodo_lectivo_barrio,
        mdp.periodo_lectivo_codigo_postal,
        -- Domicilio de procedencia (agregado a pedido)
        mdp.procedencia_calle,
        mdp.procedencia_numero,
        mdp.procedencia_departamento,
        prd.nombre AS procedencia_departamento_desc,
        mdp.procedencia_localidad,
        prl.nombre AS procedencia_localidad_desc,
        COALESCE(
            CASE
                WHEN TRIM(mdp.procedencia_departamento::text) ~ '^[0-9]+$'
                THEN TRIM(mdp.procedencia_departamento::text)::bigint
            END,
            prl.dpto_partido
        ) AS procedencia_departamento_resolved,
        mdp.procedencia_barrio,
        mdp.procedencia_codigo_postal,
        -- Datos económicos
        mde.trabajo_existe,
        mte.descripcion AS trabajo_existe_desc,
        mde.trabajo_hora_sem,
        mde.beca,
        -- Costeo de estudios (columna nombres corregidos)
        mde.costeo_estudios_familiar AS costeos_estudios_familiar,
        mde.costeo_estudios_plan_social AS costeos_estudios_plan_social,
        mde.costeo_estudios_trabajo AS costeos_estudios_trabajo,
        mde.costeo_estudios_beca AS costeos_estudios_beca,
        mde.costeo_estudios_otro AS costeos_estudios_otro,
        mde.costeo_estudios_descripcion AS costeos_estudios_descripcion,
        -- Actividades / tecnología
        mda.tecnologia_int_casa,
        mda.tecnologia_pc_casa,
        mda.deportes,
        mda.tecnologia_int_movil,
        -- Discapacidad
        mdd.disc_auditiva,
        mdd.disc_visual,
        mdd.disc_motora,
        mdd.disc_otra,
        mdd.otra_descripcion,
        mdes.nivel_estudio,
        mne.descripcion AS nivel_estudio_desc,
        mdes.institucion,
        si.nombre_abreviado AS institucion_desc,
        mdes.institucion_otra,
        mdes.colegio,
        scs.nombre AS colegio_desc,
        mdes.colegio_otro AS colegio_otra,
        ROW_NUMBER() OVER(PARTITION BY mpc.persona ORDER BY mpc.fecha_relevamiento DESC) as rn
    FROM negocio.mdp_datos_censales mpc
    LEFT JOIN negocio.mdp_datos_personales mdp ON mpc.dato_censal = mdp.dato_censal
    LEFT JOIN negocio.mdp_datos_economicos mde ON mpc.dato_censal = mde.dato_censal
    LEFT JOIN negocio.mdp_datos_actividades mda ON mpc.dato_censal = mda.dato_censal
    LEFT JOIN negocio.mdp_datos_discapacidad mdd ON mpc.dato_censal = mdd.dato_censal
    LEFT JOIN negocio.mdp_datos_estudios mdes ON mpc.persona = mdes.persona
    LEFT JOIN negocio.mdp_estados_civiles mec ON mdp.estado_civil = mec.estado_civil
    LEFT JOIN negocio.mdp_tipo_vivienda mtv ON mdp.tipo_vivienda = mtv.tipo_vivienda
    LEFT JOIN negocio.mug_localidades pll ON TRIM(mdp.periodo_lectivo_localidad::text) = pll.localidad::text
    LEFT JOIN negocio.mug_dptos_partidos pld ON (
        COALESCE(
            CASE
                WHEN TRIM(mdp.periodo_lectivo_departamento::text) ~ '^[0-9]+$'
                THEN TRIM(mdp.periodo_lectivo_departamento::text)::bigint
            END,
            pll.dpto_partido
        )
    ) = pld.dpto_partido
    LEFT JOIN negocio.mug_localidades prl ON TRIM(mdp.procedencia_localidad::text) = prl.localidad::text
    LEFT JOIN negocio.mug_dptos_partidos prd ON (
        COALESCE(
            CASE
                WHEN TRIM(mdp.procedencia_departamento::text) ~ '^[0-9]+$'
                THEN TRIM(mdp.procedencia_departamento::text)::bigint
            END,
            prl.dpto_partido
        )
    ) = prd.dpto_partido
    LEFT JOIN negocio.mdp_trabajo_existe mte ON mde.trabajo_existe = mte.trabajo_existe
    LEFT JOIN negocio.mdp_nivel_estudio mne ON mdes.nivel_estudio = mne.nivel_estudio
    LEFT JOIN negocio.sga_instituciones si ON mdes.institucion = si.institucion
    LEFT JOIN negocio.sga_colegios_secundarios scs ON mdes.colegio = scs.colegio
)
SELECT
    persona,
    fecha,
    estado_civil,
    estado_civil_desc,
    union_pareja,
    situacion_padre,
    situacion_madre,
    cobertura_salud,
    cantidad_hijos,
    tipo_vivienda,
    tipo_vivienda_desc,
    vive_con,
    periodo_lectivo_calle,
    periodo_lectivo_numero,
    periodo_lectivo_departamento_resolved AS periodo_lectivo_departamento,
    periodo_lectivo_departamento_desc,
    periodo_lectivo_localidad,
    periodo_lectivo_localidad_desc,
    periodo_lectivo_barrio,
    periodo_lectivo_codigo_postal,
    procedencia_calle,
    procedencia_numero,
    procedencia_departamento_resolved AS procedencia_departamento,
    procedencia_departamento_desc,
    procedencia_localidad,
    procedencia_localidad_desc,
    procedencia_barrio,
    procedencia_codigo_postal,
    trabajo_existe,
    trabajo_existe_desc,
    trabajo_hora_sem,
    beca,
    costeos_estudios_familiar,
    costeos_estudios_plan_social,
    costeos_estudios_trabajo,
    costeos_estudios_beca,
    costeos_estudios_otro,
    costeos_estudios_descripcion,
    tecnologia_int_casa,
    tecnologia_pc_casa,
    deportes,
    tecnologia_int_movil,
    disc_auditiva,
    disc_visual,
    disc_motora,
    disc_otra,
    otra_descripcion,
    nivel_estudio,
    nivel_estudio_desc,
    institucion,
    institucion_desc,
    institucion_otra,
    colegio,
    colegio_desc,
    colegio_otra
FROM RankedCensus WHERE rn = 1;
