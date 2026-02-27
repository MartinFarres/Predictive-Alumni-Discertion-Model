-- ============================================================================
-- DIMENSION: dim_plan_version (Curriculum/Plan Version Dimension)
-- Different versions of academic plans/curricula
-- ============================================================================

CREATE OR REPLACE TABLE silver.dim_plan_version AS
SELECT DISTINCT
    plan_version_id,
    plan_version AS plan_version_nombre
FROM bronze.students
WHERE plan_version_id IS NOT NULL

UNION

SELECT DISTINCT
    plan_version_id,
    plan_version_desc AS plan_version_nombre
FROM bronze.course_inscriptions
WHERE plan_version_id IS NOT NULL;
