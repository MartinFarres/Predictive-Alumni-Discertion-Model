SELECT
    p.persona,
    p.fecha_nacimiento,
    p.sexo,
    p.localidad_nacimiento,
    ln.nombre AS localidad_nacimiento_desc,
    p.nacionalidad,
    mn.descripcion AS nacionalidad_desc
FROM negocio.mdp_personas p
LEFT JOIN negocio.mug_localidades ln ON p.localidad_nacimiento = ln.localidad
LEFT JOIN negocio.mdp_nacionalidades mn ON p.nacionalidad = mn.nacionalidad;
