"""
KPI Card Components
Executive summary metrics display
"""

import streamlit as st


def render_kpi_cards(kpis: dict):
    """
    Render KPI cards in a row layout
    """
    if not kpis:
        st.warning("No hay datos disponibles para mostrar los indicadores.")
        return
    
    col1, col2, col3, col4 = st.columns(4)
    
    with col1:
        st.metric(
            label="Total Estudiantes",
            value=f"{int(kpis.get('total_estudiantes', 0)):,}",
            help="Número total de estudiantes en el sistema"
        )
    
    with col2:
        retention_rate = kpis.get('tasa_retencion_global', 0)
        st.metric(
            label="Tasa de Retención",
            value=f"{retention_rate:.1f}%",
            delta=None,
            help="Porcentaje de estudiantes que continúan activos"
        )
    
    with col3:
        dropout_rate = kpis.get('tasa_desercion_global', 0)
        st.metric(
            label="Tasa de Deserción",
            value=f"{dropout_rate:.1f}%",
            delta=None,
            delta_color="inverse",
            help="Porcentaje de estudiantes que abandonaron"
        )
    
    with col4:
        avg_grade = kpis.get('promedio_notas_global', 0)
        st.metric(
            label="Promedio de Notas",
            value=f"{avg_grade:.2f}",
            help="Promedio general de calificaciones"
        )
    
    # Second row
    col5, col6, col7, col8 = st.columns(4)
    
    with col5:
        st.metric(
            label="Estudiantes Retenidos",
            value=f"{int(kpis.get('total_retenidos', 0)):,}",
            help="Estudiantes que permanecen activos"
        )
    
    with col6:
        st.metric(
            label="Estudiantes Desertores",
            value=f"{int(kpis.get('total_desertores', 0)):,}",
            help="Estudiantes que abandonaron"
        )
    
    with col7:
        approval_rate = kpis.get('tasa_aprobacion_global', 0)
        st.metric(
            label="Tasa de Aprobación",
            value=f"{approval_rate:.1f}%",
            help="Porcentaje promedio de materias aprobadas"
        )
    
    with col8:
        st.metric(
            label="Estado del Sistema",
            value="Operativo",
            help="Estado actual del pipeline de datos"
        )
