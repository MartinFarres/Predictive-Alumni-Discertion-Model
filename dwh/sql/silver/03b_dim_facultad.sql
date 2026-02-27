-- ============================================================================
-- DIMENSION: dim_facultad (Faculty/Delegation Dimension)
-- Master data for faculties and university delegations
-- ============================================================================

CREATE OR REPLACE TABLE silver.dim_facultad AS
SELECT
    ROW_NUMBER() OVER (ORDER BY facultad_nombre) AS facultad_id,
    facultad_nombre,
    universidad_nombre,
    sede_provincia,
    tipo_sede,
    ubicacion_sede
FROM (
    SELECT DISTINCT
        see_institucion AS facultad_nombre,
        see_institucion_p AS universidad_nombre,
        see_provincia AS sede_provincia,
        CASE 
            WHEN see_institucion LIKE '%Delegación%' THEN 'Delegación'
            ELSE 'Sede Central'
        END AS tipo_sede,
        CASE 
            WHEN see_institucion LIKE '%San Rafael%' THEN 'San Rafael'
            WHEN see_institucion LIKE '%Zona Este%' THEN 'Zona Este'
            WHEN see_institucion LIKE '%General Alvear%' THEN 'General Alvear'
            ELSE 'Mendoza Capital'
        END AS ubicacion_sede
    FROM bronze.students
    WHERE see_institucion IS NOT NULL
) sub;
