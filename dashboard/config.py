"""
Dashboard Configuration
Database connection and application settings
"""

import os
from pathlib import Path

# Database configuration
DEFAULT_DB_PATH = Path(__file__).parent.parent / "dwh" / "data" / "warehouse.duckdb"
DATABASE_PATH = Path(os.environ.get("DWH_DATABASE_PATH", DEFAULT_DB_PATH))

# Application settings
APP_TITLE = "Sistema de Análisis de Retención Estudiantil"
APP_ICON = "🎓"
PAGE_LAYOUT = "wide"

# Color palette (institutional)
COLORS = {
    "primary": "#1f4e79",
    "secondary": "#2e75b6",
    "success": "#70ad47",
    "warning": "#ffc000",
    "danger": "#c00000",
    "neutral": "#7f7f7f",
    "background": "#f5f5f5",
}

# Risk thresholds
RISK_THRESHOLDS = {
    "high": 0.70,
    "medium": 0.40,
}

# Chart defaults
CHART_CONFIG = {
    "displayModeBar": False,
    "responsive": True,
}
