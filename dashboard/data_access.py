"""
Data Access Layer
Database queries and data retrieval for dashboard
"""

import duckdb
import pandas as pd
from config import DATABASE_PATH


def get_connection():
    """Get DuckDB connection"""
    return duckdb.connect(str(DATABASE_PATH), read_only=True)


# ============================================================================
# HELPERS - dynamic WHERE clause builder
# ============================================================================

def _append_cohort_filters(
    query: str,
    params: list,
    cohort_min: int = None,
    cohort_max: int = None,
    programs: list = None,
    faculties: list = None,
    *,
    cohort_col: str = "cohorte",
    program_col: str = "propuesta_nombre",
    faculty_col: str = "facultad_nombre",
) -> str:
    """Append optional WHERE clauses for cohort, program, and faculty filters."""
    if cohort_min is not None:
        query += f" AND {cohort_col} >= ?"
        params.append(cohort_min)
    if cohort_max is not None:
        query += f" AND {cohort_col} <= ?"
        params.append(cohort_max)
    if programs and len(programs) > 0:
        placeholders = ",".join(["?" for _ in programs])
        query += f" AND {program_col} IN ({placeholders})"
        params.extend(programs)
    if faculties and len(faculties) > 0:
        placeholders = ",".join(["?" for _ in faculties])
        query += f" AND {faculty_col} IN ({placeholders})"
        params.extend(faculties)
    return query


# ============================================================================
# FILTER OPTIONS
# ============================================================================

def get_available_cohorts() -> list:
    """Get list of available cohort years for filtering"""
    query = """
    SELECT DISTINCT cohorte 
    FROM gold.mart_cohort_analysis 
    WHERE cohorte IS NOT NULL 
    ORDER BY cohorte DESC
    """
    with get_connection() as conn:
        result = conn.execute(query).df()
    return result["cohorte"].tolist()


def get_available_programs() -> list:
    """Get list of available programs for filtering"""
    query = """
    SELECT DISTINCT propuesta_nombre 
    FROM gold.mart_cohort_analysis 
    WHERE propuesta_nombre IS NOT NULL 
    ORDER BY propuesta_nombre
    """
    with get_connection() as conn:
        result = conn.execute(query).df()
    return result["propuesta_nombre"].tolist()


def get_available_faculties() -> list:
    """Get list of available faculties for filtering"""
    query = """
    SELECT DISTINCT facultad_nombre 
    FROM gold.mart_cohort_analysis 
    WHERE facultad_nombre IS NOT NULL 
    ORDER BY facultad_nombre
    """
    with get_connection() as conn:
        result = conn.execute(query).df()
    return result["facultad_nombre"].tolist()


# ============================================================================
# KPIs AND SUMMARIES (filtered)
# ============================================================================

def get_overall_kpis(
    cohort_min: int = None,
    cohort_max: int = None,
    programs: list = None,
    faculties: list = None,
) -> dict:
    """Get high-level KPIs for executive summary, with optional filters."""
    query = """
    SELECT
        SUM(total_estudiantes) AS total_estudiantes,
        SUM(total_desertores) AS total_desertores,
        SUM(total_retenidos) AS total_retenidos,
        ROUND(SUM(total_desertores)::FLOAT / NULLIF(SUM(total_estudiantes), 0) * 100, 1) AS tasa_desercion_global,
        ROUND(SUM(total_retenidos)::FLOAT / NULLIF(SUM(total_estudiantes), 0) * 100, 1) AS tasa_retencion_global,
        ROUND(AVG(promedio_notas_cohorte), 2) AS promedio_notas_global,
        ROUND(AVG(tasa_aprobacion_cohorte_pct), 1) AS tasa_aprobacion_global
    FROM gold.mart_cohort_analysis
    WHERE cohorte IS NOT NULL
    """
    params: list = []
    query = _append_cohort_filters(query, params, cohort_min, cohort_max, programs, faculties)
    with get_connection() as conn:
        result = conn.execute(query, params).df()
    if result.empty:
        return {}
    return result.iloc[0].to_dict()


def get_cohort_summary(
    cohort_min: int = None,
    cohort_max: int = None,
    programs: list = None,
    faculties: list = None,
) -> pd.DataFrame:
    """Cohort-level summary statistics with filters."""
    query = """
    SELECT 
        cohorte,
        propuesta_nombre,
        facultad_nombre,
        total_estudiantes,
        total_desertores,
        total_retenidos,
        tasa_desercion_pct,
        tasa_retencion_pct,
        promedio_anios_hasta_dropout,
        promedio_notas_cohorte,
        tasa_aprobacion_cohorte_pct
    FROM gold.mart_cohort_analysis
    WHERE cohorte IS NOT NULL
    """
    params: list = []
    query = _append_cohort_filters(query, params, cohort_min, cohort_max, programs, faculties)
    query += " ORDER BY cohorte DESC, total_estudiantes DESC"
    with get_connection() as conn:
        return conn.execute(query, params).df()


def get_cohort_trend(
    cohort_min: int = None,
    cohort_max: int = None,
    programs: list = None,
    faculties: list = None,
) -> pd.DataFrame:
    """Dropout and retention trends by cohort year."""
    query = """
    SELECT
        cohorte,
        SUM(total_estudiantes) AS total_estudiantes,
        SUM(total_desertores) AS total_desertores,
        SUM(total_retenidos) AS total_retenidos,
        ROUND(SUM(total_desertores)::FLOAT / NULLIF(SUM(total_estudiantes), 0) * 100, 1) AS tasa_desercion,
        ROUND(SUM(total_retenidos)::FLOAT / NULLIF(SUM(total_estudiantes), 0) * 100, 1) AS tasa_retencion
    FROM gold.mart_cohort_analysis
    WHERE cohorte IS NOT NULL
    """
    params: list = []
    query = _append_cohort_filters(query, params, cohort_min, cohort_max, programs, faculties)
    query += " GROUP BY cohorte ORDER BY cohorte"
    with get_connection() as conn:
        return conn.execute(query, params).df()


def get_program_comparison(
    cohort_min: int = None,
    cohort_max: int = None,
    programs: list = None,
    faculties: list = None,
) -> pd.DataFrame:
    """Comparative metrics by academic program."""
    query = """
    SELECT
        propuesta_nombre AS programa,
        SUM(total_estudiantes) AS total_estudiantes,
        ROUND(SUM(total_desertores)::FLOAT / NULLIF(SUM(total_estudiantes), 0) * 100, 1) AS tasa_desercion,
        ROUND(AVG(promedio_notas_cohorte), 2) AS promedio_notas,
        ROUND(AVG(tasa_aprobacion_cohorte_pct), 1) AS tasa_aprobacion
    FROM gold.mart_cohort_analysis
    WHERE cohorte IS NOT NULL AND propuesta_nombre IS NOT NULL
    """
    params: list = []
    query = _append_cohort_filters(query, params, cohort_min, cohort_max, programs, faculties)
    query += " GROUP BY propuesta_nombre HAVING SUM(total_estudiantes) >= 10 ORDER BY tasa_desercion DESC"
    with get_connection() as conn:
        return conn.execute(query, params).df()


# ============================================================================
# FACULTY-LEVEL QUERIES
# ============================================================================

def get_faculty_comparison(
    cohort_min: int = None,
    cohort_max: int = None,
    programs: list = None,
) -> pd.DataFrame:
    """Comparative metrics by faculty / delegation."""
    query = """
    SELECT
        facultad_nombre AS sede,
        SUM(total_estudiantes) AS total_estudiantes,
        SUM(total_desertores) AS total_desertores,
        ROUND(SUM(total_desertores)::FLOAT / NULLIF(SUM(total_estudiantes), 0) * 100, 1) AS tasa_desercion,
        ROUND(SUM(total_retenidos)::FLOAT / NULLIF(SUM(total_estudiantes), 0) * 100, 1) AS tasa_retencion,
        ROUND(AVG(promedio_notas_cohorte), 2) AS promedio_notas,
        ROUND(AVG(tasa_aprobacion_cohorte_pct), 1) AS tasa_aprobacion
    FROM gold.mart_cohort_analysis
    WHERE cohorte IS NOT NULL AND facultad_nombre IS NOT NULL
    """
    params: list = []
    query = _append_cohort_filters(query, params, cohort_min, cohort_max, programs, faculties=None)
    query += " GROUP BY facultad_nombre ORDER BY total_estudiantes DESC"
    with get_connection() as conn:
        return conn.execute(query, params).df()


def get_faculty_trend(
    cohort_min: int = None,
    cohort_max: int = None,
) -> pd.DataFrame:
    """Dropout rate trend per faculty over cohort years."""
    query = """
    SELECT
        cohorte,
        facultad_nombre AS sede,
        SUM(total_estudiantes) AS total_estudiantes,
        ROUND(SUM(total_desertores)::FLOAT / NULLIF(SUM(total_estudiantes), 0) * 100, 1) AS tasa_desercion
    FROM gold.mart_cohort_analysis
    WHERE cohorte IS NOT NULL AND facultad_nombre IS NOT NULL
    """
    params: list = []
    query = _append_cohort_filters(query, params, cohort_min, cohort_max, programs=None, faculties=None)
    query += " GROUP BY cohorte, facultad_nombre ORDER BY cohorte, facultad_nombre"
    with get_connection() as conn:
        return conn.execute(query, params).df()


def get_faculty_risk_summary() -> pd.DataFrame:
    """Risk-level distribution broken down by faculty."""
    query = """
    SELECT
        facultad_nombre AS sede,
        CASE 
            WHEN tasa_aprobacion < 0.3 OR promedio_asistencia < 50 THEN 'Alto'
            WHEN tasa_aprobacion < 0.6 OR promedio_asistencia < 70 THEN 'Medio'
            ELSE 'Bajo'
        END AS nivel_riesgo,
        COUNT(DISTINCT alumno_id) AS cantidad_estudiantes
    FROM gold.mart_student_risk_features
    WHERE anio_academico = (
        SELECT MAX(anio_academico) FROM gold.mart_student_risk_features
    )
    AND facultad_nombre IS NOT NULL
    GROUP BY facultad_nombre, nivel_riesgo
    ORDER BY facultad_nombre,
        CASE nivel_riesgo WHEN 'Alto' THEN 1 WHEN 'Medio' THEN 2 ELSE 3 END
    """
    with get_connection() as conn:
        return conn.execute(query).df()


# ============================================================================
# RISK AND ACADEMIC (unchanged, but supporting optional faculty filter)
# ============================================================================

def get_risk_distribution(faculties: list = None) -> pd.DataFrame:
    """Distribution of students by risk level."""
    query = """
    SELECT
        CASE 
            WHEN tasa_aprobacion < 0.3 OR promedio_asistencia < 50 THEN 'Alto'
            WHEN tasa_aprobacion < 0.6 OR promedio_asistencia < 70 THEN 'Medio'
            ELSE 'Bajo'
        END AS nivel_riesgo,
        COUNT(DISTINCT alumno_id) AS cantidad_estudiantes
    FROM gold.mart_student_risk_features
    WHERE anio_academico = (
        SELECT MAX(anio_academico) FROM gold.mart_student_risk_features
    )
    """
    params: list = []
    if faculties and len(faculties) > 0:
        placeholders = ",".join(["?" for _ in faculties])
        query += f" AND facultad_nombre IN ({placeholders})"
        params.extend(faculties)
    query += """
    GROUP BY nivel_riesgo
    ORDER BY 
        CASE nivel_riesgo WHEN 'Alto' THEN 1 WHEN 'Medio' THEN 2 ELSE 3 END
    """
    with get_connection() as conn:
        return conn.execute(query, params).df()


def get_academic_trends(faculties: list = None) -> pd.DataFrame:
    """Academic performance trends over time."""
    query = """
    SELECT
        sas.anio_academico,
        COUNT(DISTINCT sas.alumno_id) AS estudiantes_activos,
        ROUND(AVG(sas.promedio_notas), 2) AS promedio_notas,
        ROUND(AVG(sas.tasa_aprobacion) * 100, 1) AS tasa_aprobacion,
        ROUND(AVG(sas.tasa_ausentismo) * 100, 1) AS tasa_ausentismo
    FROM gold.mart_student_academic_summary sas
    """
    params: list = []
    if faculties and len(faculties) > 0:
        query += " JOIN silver.dim_student ds ON sas.alumno_id = ds.alumno_id"
        placeholders = ",".join(["?" for _ in faculties])
        query += f" WHERE ds.facultad_nombre IN ({placeholders})"
        params.extend(faculties)
        query += " AND sas.anio_academico IS NOT NULL"
    else:
        query += " WHERE sas.anio_academico IS NOT NULL"
    query += " GROUP BY sas.anio_academico ORDER BY sas.anio_academico"
    with get_connection() as conn:
        return conn.execute(query, params).df()


def get_engagement_summary(faculties: list = None) -> pd.DataFrame:
    """Engagement metrics summary."""
    query = """
    SELECT
        se.anio_academico,
        ROUND(AVG(se.promedio_asistencia), 1) AS promedio_asistencia,
        ROUND(AVG(se.total_inasistencias), 1) AS promedio_inasistencias,
        ROUND(AVG(se.reinscripciones_anio), 2) AS promedio_reinscripciones
    FROM gold.mart_student_engagement se
    """
    params: list = []
    if faculties and len(faculties) > 0:
        query += " JOIN silver.dim_student ds ON se.alumno_id = ds.alumno_id"
        placeholders = ",".join(["?" for _ in faculties])
        query += f" WHERE ds.facultad_nombre IN ({placeholders})"
        params.extend(faculties)
        query += " AND se.anio_academico IS NOT NULL"
    else:
        query += " WHERE se.anio_academico IS NOT NULL"
    query += " GROUP BY se.anio_academico ORDER BY se.anio_academico"
    with get_connection() as conn:
        return conn.execute(query, params).df()


def get_dropout_by_year_in_program(faculties: list = None) -> pd.DataFrame:
    """Dropout distribution by years since enrollment."""
    query = """
    SELECT
        anios_hasta_dropout AS anio_desercion,
        COUNT(*) AS cantidad
    FROM (
        SELECT
            MIN(fd.anio_academico) - ds.anio_ingreso AS anios_hasta_dropout
        FROM silver.fact_dropout fd
        JOIN silver.dim_student ds ON fd.alumno_id = ds.alumno_id
        WHERE ds.anio_ingreso IS NOT NULL
    """
    params: list = []
    if faculties and len(faculties) > 0:
        placeholders = ",".join(["?" for _ in faculties])
        query += f" AND ds.facultad_nombre IN ({placeholders})"
        params.extend(faculties)
    query += """
        GROUP BY fd.alumno_id, ds.anio_ingreso
    ) sub
    WHERE anios_hasta_dropout >= 0 AND anios_hasta_dropout <= 10
    GROUP BY anios_hasta_dropout
    ORDER BY anios_hasta_dropout
    """
    with get_connection() as conn:
        return conn.execute(query, params).df()

