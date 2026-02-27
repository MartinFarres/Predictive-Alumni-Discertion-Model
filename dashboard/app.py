"""
Dashboard BI - Análisis de Retención Estudiantil
Panel ejecutivo para directivos universitarios
"""

import streamlit as st
from pathlib import Path

from config import APP_TITLE, APP_ICON, PAGE_LAYOUT, DATABASE_PATH
import data_access as data
from components import (
    render_kpi_cards,
    render_cohort_trend_chart,
    render_program_comparison_chart,
    render_risk_distribution_chart,
    render_academic_trend_chart,
    render_dropout_timing_chart,
    render_student_count_trend,
    render_faculty_comparison_chart,
    render_faculty_trend_chart,
    render_faculty_risk_chart,
)
from components.filters import render_sidebar_filters, render_date_info


# Page configuration
st.set_page_config(
    page_title=APP_TITLE,
    page_icon=APP_ICON,
    layout=PAGE_LAYOUT,
    initial_sidebar_state="expanded",
)

# Load custom CSS
css_path = Path(__file__).parent / "assets" / "styles.css"
if css_path.exists():
    with open(css_path) as f:
        st.markdown(f"<style>{f.read()}</style>", unsafe_allow_html=True)


def check_database_connection() -> bool:
    """Verify database connectivity"""
    if not DATABASE_PATH.exists():
        st.error(
            f"Base de datos no encontrada en: {DATABASE_PATH}\n\n"
            "Ejecute el pipeline DWH para generar los datos:\n"
            "```\npython -m dwh.main\n```"
        )
        return False
    return True


def main():
    # Header
    st.title("Sistema de Análisis de Retención Estudiantil")
    st.markdown(
        "Panel ejecutivo para el monitoreo de indicadores de retención y deserción estudiantil."
    )

    # Check database
    if not check_database_connection():
        return

    # ── Sidebar filters ─────────────────────────────────────────────
    try:
        cohorts = data.get_available_cohorts()
        programs = data.get_available_programs()
        faculties = data.get_available_faculties()
        cohort_range, selected_programs, selected_faculties = render_sidebar_filters(
            cohorts, programs, faculties,
        )
        render_date_info()
    except Exception as e:
        st.sidebar.error(f"Error cargando filtros: {e}")
        cohort_range, selected_programs, selected_faculties = None, None, None

    # Derive cohort min/max from range tuple
    cohort_min = cohort_range[0] if cohort_range else None
    cohort_max = cohort_range[1] if cohort_range else None

    # ── Main content ────────────────────────────────────────────────
    try:
        # KPIs Section
        st.header("Resumen Ejecutivo")
        kpis = data.get_overall_kpis(cohort_min, cohort_max, selected_programs, selected_faculties)
        render_kpi_cards(kpis)

        st.markdown("---")

        # Tabs for different analyses
        tab1, tab2, tab3, tab4, tab5 = st.tabs([
            "📊 Análisis por Cohorte",
            "🎓 Análisis por Programa",
            "🏛️ Análisis por Sede",
            "⚠️ Indicadores de Riesgo",
            "📈 Rendimiento Académico",
        ])

        # ── TAB 1: Cohorte ──────────────────────────────────────────
        with tab1:
            st.subheader("Evolución Temporal por Cohorte de Ingreso")

            col1, col2 = st.columns(2)

            with col1:
                cohort_trend = data.get_cohort_trend(
                    cohort_min, cohort_max, selected_programs, selected_faculties,
                )
                fig = render_cohort_trend_chart(cohort_trend)
                st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

            with col2:
                fig = render_student_count_trend(cohort_trend)
                st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

            # Detailed cohort table
            with st.expander("Ver datos detallados por cohorte"):
                cohort_data = data.get_cohort_summary(
                    cohort_min, cohort_max, selected_programs, selected_faculties,
                )
                if not cohort_data.empty:
                    st.dataframe(
                        cohort_data,
                        use_container_width=True,
                        hide_index=True,
                        column_config={
                            "cohorte": "Cohorte",
                            "propuesta_nombre": "Programa",
                            "facultad_nombre": "Sede",
                            "total_estudiantes": "Total Estudiantes",
                            "total_desertores": "Desertores",
                            "total_retenidos": "Retenidos",
                            "tasa_desercion_pct": st.column_config.NumberColumn(
                                "Tasa Deserción (%)", format="%.1f%%"
                            ),
                            "tasa_retencion_pct": st.column_config.NumberColumn(
                                "Tasa Retención (%)", format="%.1f%%"
                            ),
                        },
                    )

        # ── TAB 2: Programa ─────────────────────────────────────────
        with tab2:
            st.subheader("Comparativo por Programa Académico")

            program_data = data.get_program_comparison(
                cohort_min, cohort_max, selected_programs, selected_faculties,
            )
            fig = render_program_comparison_chart(program_data)
            st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

            with st.expander("Ver métricas completas por programa"):
                if not program_data.empty:
                    st.dataframe(
                        program_data,
                        use_container_width=True,
                        hide_index=True,
                        column_config={
                            "programa": "Programa",
                            "total_estudiantes": "Total Estudiantes",
                            "tasa_desercion": st.column_config.NumberColumn(
                                "Tasa Deserción (%)", format="%.1f%%"
                            ),
                            "promedio_notas": st.column_config.NumberColumn(
                                "Promedio Notas", format="%.2f"
                            ),
                            "tasa_aprobacion": st.column_config.NumberColumn(
                                "Tasa Aprobación (%)", format="%.1f%%"
                            ),
                        },
                    )

        # ── TAB 3: Sede / Delegación (NEW) ──────────────────────────
        with tab3:
            st.subheader("Comparativo por Sede / Delegación")

            col1, col2 = st.columns(2)

            with col1:
                faculty_data = data.get_faculty_comparison(
                    cohort_min, cohort_max, selected_programs,
                )
                fig = render_faculty_comparison_chart(faculty_data)
                st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

            with col2:
                faculty_risk = data.get_faculty_risk_summary()
                fig = render_faculty_risk_chart(faculty_risk)
                st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

            # Trend across faculties
            faculty_trend = data.get_faculty_trend(cohort_min, cohort_max)
            fig = render_faculty_trend_chart(faculty_trend)
            st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

            # Summary table
            with st.expander("Ver métricas completas por sede"):
                if not faculty_data.empty:
                    st.dataframe(
                        faculty_data,
                        use_container_width=True,
                        hide_index=True,
                        column_config={
                            "sede": "Sede / Delegación",
                            "total_estudiantes": "Total Estudiantes",
                            "total_desertores": "Desertores",
                            "tasa_desercion": st.column_config.NumberColumn(
                                "Tasa Deserción (%)", format="%.1f%%"
                            ),
                            "tasa_retencion": st.column_config.NumberColumn(
                                "Tasa Retención (%)", format="%.1f%%"
                            ),
                            "promedio_notas": st.column_config.NumberColumn(
                                "Promedio Notas", format="%.2f"
                            ),
                            "tasa_aprobacion": st.column_config.NumberColumn(
                                "Tasa Aprobación (%)", format="%.1f%%"
                            ),
                        },
                    )

        # ── TAB 4: Riesgo ───────────────────────────────────────────
        with tab4:
            st.subheader("Distribución de Estudiantes por Nivel de Riesgo")

            col1, col2 = st.columns(2)

            with col1:
                risk_data = data.get_risk_distribution(selected_faculties)
                fig = render_risk_distribution_chart(risk_data)
                st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

            with col2:
                dropout_timing = data.get_dropout_by_year_in_program(selected_faculties)
                fig = render_dropout_timing_chart(dropout_timing)
                st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

            st.info(
                "**Clasificación de Riesgo:**\n"
                "- **Alto**: Tasa de aprobación < 30% o asistencia < 50%\n"
                "- **Medio**: Tasa de aprobación < 60% o asistencia < 70%\n"
                "- **Bajo**: Indicadores dentro de parámetros normales"
            )

        # ── TAB 5: Rendimiento ──────────────────────────────────────
        with tab5:
            st.subheader("Tendencias de Rendimiento Académico")

            academic_data = data.get_academic_trends(selected_faculties)
            fig = render_academic_trend_chart(academic_data)
            st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

            st.subheader("Indicadores de Compromiso Estudiantil")

            engagement_data = data.get_engagement_summary(selected_faculties)
            if not engagement_data.empty:
                col1, col2, col3 = st.columns(3)
                latest = engagement_data.iloc[-1] if len(engagement_data) > 0 else None

                if latest is not None:
                    with col1:
                        st.metric("Promedio Asistencia", f"{latest['promedio_asistencia']:.1f}%")
                    with col2:
                        st.metric("Promedio Inasistencias", f"{latest['promedio_inasistencias']:.1f}")
                    with col3:
                        st.metric("Reinscripciones Promedio", f"{latest['promedio_reinscripciones']:.2f}")

            with st.expander("Ver datos históricos de rendimiento"):
                if not academic_data.empty:
                    st.dataframe(
                        academic_data,
                        use_container_width=True,
                        hide_index=True,
                        column_config={
                            "anio_academico": "Año",
                            "estudiantes_activos": "Estudiantes Activos",
                            "promedio_notas": st.column_config.NumberColumn(
                                "Promedio Notas", format="%.2f"
                            ),
                            "tasa_aprobacion": st.column_config.NumberColumn(
                                "Tasa Aprobación (%)", format="%.1f%%"
                            ),
                            "tasa_ausentismo": st.column_config.NumberColumn(
                                "Tasa Ausentismo (%)", format="%.1f%%"
                            ),
                        },
                    )

        # Footer
        st.markdown("---")
        st.caption(
            "Sistema de Análisis de Retención Estudiantil | "
            "Datos provenientes del Data Warehouse institucional"
        )

    except Exception as e:
        st.error(f"Error cargando datos: {e}")
        st.exception(e)


if __name__ == "__main__":
    main()
