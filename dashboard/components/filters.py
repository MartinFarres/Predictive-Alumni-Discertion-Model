"""
Filter Components
Sidebar filters for dashboard
"""

import streamlit as st
from typing import Tuple, List, Optional


def render_sidebar_filters(
    cohorts: List[int],
    programs: List[str],
    faculties: List[str] = None,
) -> Tuple[Optional[Tuple[int, int]], Optional[List[str]], Optional[List[str]]]:
    """
    Render sidebar filters and return selected values.
    Returns (cohort_range, selected_programs, selected_faculties).
    cohort_range is a (min, max) tuple or None.
    """
    st.sidebar.header("Filtros")

    # ── Faculty filter ──────────────────────────────────────────────
    st.sidebar.subheader("Sede / Delegación")

    if faculties:
        all_faculties = st.sidebar.checkbox("Todas las sedes", value=True)
        if all_faculties:
            selected_faculties = None  # None = no filter (all)
        else:
            selected_faculties = st.sidebar.multiselect(
                "Seleccione sedes",
                options=faculties,
                default=faculties,
                help="Filtre por sede o delegación",
            )
    else:
        selected_faculties = None

    # ── Cohort filter ───────────────────────────────────────────────
    st.sidebar.subheader("Cohorte")

    if cohorts:
        min_year = min(cohorts)
        max_year = max(cohorts)

        selected_cohort_range = st.sidebar.slider(
            "Rango de años",
            min_value=min_year,
            max_value=max_year,
            value=(min_year, max_year),
            help="Seleccione el rango de años de ingreso",
        )
    else:
        selected_cohort_range = None

    # ── Program filter ──────────────────────────────────────────────
    st.sidebar.subheader("Programa Académico")

    if programs:
        all_programs = st.sidebar.checkbox("Todos los programas", value=True)
        if all_programs:
            selected_programs = None  # None = no filter (all)
        else:
            selected_programs = st.sidebar.multiselect(
                "Seleccione programas",
                options=programs,
                default=programs[:5] if len(programs) > 5 else programs,
                help="Seleccione uno o más programas académicos",
            )
    else:
        selected_programs = None

    # ── Info ─────────────────────────────────────────────────────────
    st.sidebar.markdown("---")
    st.sidebar.caption(
        "Los filtros se aplican a todas las visualizaciones del dashboard."
    )

    return selected_cohort_range, selected_programs, selected_faculties


def render_date_info():
    """Render data freshness information in sidebar"""
    st.sidebar.markdown("---")
    st.sidebar.subheader("Información de Datos")
    st.sidebar.caption(
        "Última actualización del Data Warehouse: consultar logs del pipeline ETL"
    )
