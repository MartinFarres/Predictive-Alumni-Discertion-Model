"""Dashboard UI Components"""
from .kpis import render_kpi_cards
from .charts import (
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
from .filters import render_sidebar_filters
