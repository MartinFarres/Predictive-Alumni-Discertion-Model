-- ============================================================================
-- DIMENSION: dim_ubicacion (Academic Site/Campus Dimension)
-- Physical locations where students attend (SEE - Sede)
-- ============================================================================

CREATE OR REPLACE TABLE silver.dim_ubicacion AS
SELECT DISTINCT
    ubicacion AS ubicacion_id,
    see_nombre,
    see_calle,
    see_numero,
    see_codigo_postal,
    see_institucion,
    see_institucion_p,
    see_localidad,
    see_dpto,
    see_provincia
FROM bronze.students
WHERE ubicacion IS NOT NULL;
