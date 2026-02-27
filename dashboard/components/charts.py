"""
Chart Components
Visualization functions using Plotly
"""

import plotly.express as px
import plotly.graph_objects as go
import pandas as pd
from config import COLORS, CHART_CONFIG


# ============================================================================
# EMPTY FIGURE HELPER
# ============================================================================

def _empty_figure(msg: str = "No hay datos disponibles") -> go.Figure:
    return go.Figure().add_annotation(
        text=msg, xref="paper", yref="paper", x=0.5, y=0.5, showarrow=False
    )


# ============================================================================
# EXISTING CHARTS (unchanged)
# ============================================================================

def render_cohort_trend_chart(df: pd.DataFrame) -> go.Figure:
    """Line chart: retention & dropout rates over cohort years."""
    if df.empty:
        return _empty_figure()

    fig = go.Figure()
    fig.add_trace(go.Scatter(
        x=df["cohorte"], y=df["tasa_retencion"],
        name="Tasa de Retención", mode="lines+markers",
        line=dict(color=COLORS["success"], width=3), marker=dict(size=8),
    ))
    fig.add_trace(go.Scatter(
        x=df["cohorte"], y=df["tasa_desercion"],
        name="Tasa de Deserción", mode="lines+markers",
        line=dict(color=COLORS["danger"], width=3), marker=dict(size=8),
    ))
    fig.update_layout(
        title="Evolución de Retención y Deserción por Cohorte",
        xaxis_title="Año de Ingreso (Cohorte)", yaxis_title="Porcentaje (%)",
        legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
        hovermode="x unified", plot_bgcolor="white",
        yaxis=dict(range=[0, 100], gridcolor="#e0e0e0"),
        xaxis=dict(gridcolor="#e0e0e0"),
    )
    return fig


def render_program_comparison_chart(df: pd.DataFrame) -> go.Figure:
    """Horizontal bar chart comparing dropout rates by program."""
    if df.empty:
        return _empty_figure()

    df_sorted = df.nlargest(15, "tasa_desercion")
    colors = [
        COLORS["danger"] if r > 30 else COLORS["warning"] if r > 15 else COLORS["success"]
        for r in df_sorted["tasa_desercion"]
    ]
    fig = go.Figure(go.Bar(
        x=df_sorted["tasa_desercion"], y=df_sorted["programa"],
        orientation="h", marker_color=colors,
        text=df_sorted["tasa_desercion"].apply(lambda x: f"{x:.1f}%"),
        textposition="outside",
    ))
    fig.update_layout(
        title="Tasa de Deserción por Programa Académico",
        xaxis_title="Tasa de Deserción (%)", yaxis_title="",
        plot_bgcolor="white",
        xaxis=dict(gridcolor="#e0e0e0", range=[0, max(df_sorted["tasa_desercion"]) * 1.2]),
        yaxis=dict(autorange="reversed"),
        height=max(400, len(df_sorted) * 30),
    )
    return fig


def render_risk_distribution_chart(df: pd.DataFrame) -> go.Figure:
    """Donut chart: student distribution by risk level."""
    if df.empty:
        return _empty_figure()

    color_map = {"Alto": COLORS["danger"], "Medio": COLORS["warning"], "Bajo": COLORS["success"]}
    colors = [color_map.get(n, COLORS["neutral"]) for n in df["nivel_riesgo"]]
    total = df["cantidad_estudiantes"].sum()

    fig = go.Figure(go.Pie(
        labels=df["nivel_riesgo"], values=df["cantidad_estudiantes"],
        hole=0.5, marker_colors=colors,
        textinfo="label+percent", textposition="outside",
        pull=[0.05 if n == "Alto" else 0 for n in df["nivel_riesgo"]],
    ))
    fig.update_layout(
        title="Distribución de Estudiantes por Nivel de Riesgo",
        annotations=[dict(text=f"{total:,}<br>Total", x=0.5, y=0.5, font_size=16, showarrow=False)],
        showlegend=True,
        legend=dict(orientation="h", yanchor="bottom", y=-0.1, xanchor="center", x=0.5),
    )
    return fig


def render_academic_trend_chart(df: pd.DataFrame) -> go.Figure:
    """Multi-line chart: academic metrics over time (dual y-axis)."""
    if df.empty:
        return _empty_figure()

    fig = go.Figure()
    fig.add_trace(go.Scatter(
        x=df["anio_academico"], y=df["tasa_aprobacion"],
        name="Tasa de Aprobación (%)", mode="lines+markers",
        line=dict(color=COLORS["success"], width=2), yaxis="y",
    ))
    fig.add_trace(go.Scatter(
        x=df["anio_academico"], y=df["promedio_notas"],
        name="Promedio de Notas", mode="lines+markers",
        line=dict(color=COLORS["primary"], width=2), yaxis="y2",
    ))
    fig.update_layout(
        title="Tendencia de Rendimiento Académico",
        xaxis_title="Año Académico",
        yaxis=dict(
            title="Tasa de Aprobación (%)",
            title_font=dict(color=COLORS["success"]),
            tickfont=dict(color=COLORS["success"]),
            range=[0, 100], gridcolor="#e0e0e0",
        ),
        yaxis2=dict(
            title="Promedio de Notas",
            title_font=dict(color=COLORS["primary"]),
            tickfont=dict(color=COLORS["primary"]),
            anchor="x", overlaying="y", side="right", range=[0, 10],
        ),
        legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
        hovermode="x unified", plot_bgcolor="white",
        xaxis=dict(gridcolor="#e0e0e0"),
    )
    return fig


def render_dropout_timing_chart(df: pd.DataFrame) -> go.Figure:
    """Bar chart: when students drop out (by year in program)."""
    if df.empty:
        return _empty_figure()

    max_val = df["cantidad"].max()
    colors = [f"rgba(192, 0, 0, {0.3 + 0.7 * (v / max_val)})" for v in df["cantidad"]]

    fig = go.Figure(go.Bar(
        x=df["anio_desercion"], y=df["cantidad"],
        marker_color=colors, text=df["cantidad"], textposition="outside",
    ))
    fig.update_layout(
        title="Momento de Deserción (Años desde Ingreso)",
        xaxis_title="Años en el Programa", yaxis_title="Cantidad de Desertores",
        plot_bgcolor="white",
        xaxis=dict(tickmode="linear", dtick=1, gridcolor="#e0e0e0"),
        yaxis=dict(gridcolor="#e0e0e0"), bargap=0.3,
    )
    return fig


def render_student_count_trend(df: pd.DataFrame) -> go.Figure:
    """Area chart: student count over time."""
    if df.empty:
        return _empty_figure()

    fig = go.Figure()
    fig.add_trace(go.Scatter(
        x=df["cohorte"], y=df["total_estudiantes"],
        fill="tozeroy", mode="lines+markers",
        line=dict(color=COLORS["primary"], width=2),
        fillcolor="rgba(31, 78, 121, 0.3)", name="Total Estudiantes",
    ))
    fig.update_layout(
        title="Volumen de Estudiantes por Cohorte",
        xaxis_title="Año de Ingreso", yaxis_title="Cantidad de Estudiantes",
        plot_bgcolor="white",
        xaxis=dict(gridcolor="#e0e0e0"), yaxis=dict(gridcolor="#e0e0e0"),
        hovermode="x unified",
    )
    return fig


# ============================================================================
# NEW — FACULTY / SEDE CHARTS
# ============================================================================

# Color palette for up to 8 faculties
_FACULTY_PALETTE = [
    COLORS["primary"], COLORS["secondary"], COLORS["success"],
    COLORS["warning"], COLORS["danger"], COLORS["neutral"],
    "#9b59b6", "#1abc9c",
]


def render_faculty_comparison_chart(df: pd.DataFrame) -> go.Figure:
    """Grouped bar chart comparing key metrics across faculties."""
    if df.empty:
        return _empty_figure()

    fig = go.Figure()

    fig.add_trace(go.Bar(
        x=df["sede"], y=df["tasa_desercion"],
        name="Deserción (%)", marker_color=COLORS["danger"],
        text=df["tasa_desercion"].apply(lambda x: f"{x:.1f}%"),
        textposition="outside",
    ))
    fig.add_trace(go.Bar(
        x=df["sede"], y=df["tasa_retencion"],
        name="Retención (%)", marker_color=COLORS["success"],
        text=df["tasa_retencion"].apply(lambda x: f"{x:.1f}%"),
        textposition="outside",
    ))

    fig.update_layout(
        title="Comparativo de Deserción y Retención por Sede",
        xaxis_title="", yaxis_title="Porcentaje (%)",
        barmode="group", plot_bgcolor="white",
        yaxis=dict(range=[0, 110], gridcolor="#e0e0e0"),
        legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
    )
    return fig


def render_faculty_trend_chart(df: pd.DataFrame) -> go.Figure:
    """Multi-line chart: dropout rate trend per faculty over cohort years."""
    if df.empty:
        return _empty_figure()

    sedes = df["sede"].unique()
    fig = go.Figure()

    for i, sede in enumerate(sedes):
        sub = df[df["sede"] == sede]
        fig.add_trace(go.Scatter(
            x=sub["cohorte"], y=sub["tasa_desercion"],
            name=sede, mode="lines+markers",
            line=dict(color=_FACULTY_PALETTE[i % len(_FACULTY_PALETTE)], width=2),
            marker=dict(size=6),
        ))

    fig.update_layout(
        title="Tendencia de Deserción por Sede / Delegación",
        xaxis_title="Cohorte", yaxis_title="Tasa de Deserción (%)",
        hovermode="x unified", plot_bgcolor="white",
        yaxis=dict(range=[0, 100], gridcolor="#e0e0e0"),
        xaxis=dict(gridcolor="#e0e0e0"),
        legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
    )
    return fig


def render_faculty_risk_chart(df: pd.DataFrame) -> go.Figure:
    """Stacked bar chart: risk distribution per faculty."""
    if df.empty:
        return _empty_figure()

    color_map = {"Alto": COLORS["danger"], "Medio": COLORS["warning"], "Bajo": COLORS["success"]}

    for nivel in ["Bajo", "Medio", "Alto"]:
        # Ensure all levels exist for each sede
        pass

    fig = go.Figure()
    for nivel in ["Bajo", "Medio", "Alto"]:
        sub = df[df["nivel_riesgo"] == nivel]
        fig.add_trace(go.Bar(
            x=sub["sede"], y=sub["cantidad_estudiantes"],
            name=nivel, marker_color=color_map.get(nivel, COLORS["neutral"]),
        ))

    fig.update_layout(
        title="Distribución de Riesgo por Sede",
        xaxis_title="", yaxis_title="Cantidad de Estudiantes",
        barmode="stack", plot_bgcolor="white",
        yaxis=dict(gridcolor="#e0e0e0"),
        legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
    )
    return fig
