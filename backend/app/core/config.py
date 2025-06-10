import os
import logging
from typing import Dict, Any
from functools import lru_cache
from dotenv import load_dotenv
import platform

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler("logs/app.log")
    ]
)

logger = logging.getLogger(__name__)

# Create logs directory if it doesn't exist
os.makedirs("logs", exist_ok=True)


class Settings:
    """Application settings loaded from environment variables."""
    PROJECT_NAME: str = "QLDSV-HTC API"
    PROJECT_DESCRIPTION: str = "API for QLDSV-HTC (Quản lý điểm sinh viên hệ tín chỉ)"
    PROJECT_VERSION: str = "1.0.0"

    # Database connection settings
    DB_HOST: str = os.getenv("DB_HOST", "localhost")
    DB_PORT: str = os.getenv("DB_PORT", "1434")
    DB_NAME: str = os.getenv("DB_NAME", "QLDSV_HTC")
    DB_CONTAINER_NAME: str = os.getenv("DB_CONTAINER_NAME", "qldsv-sqlserver")

    # Credentials
    MSSQL_APP_USER: str = os.getenv("MSSQL_APP_USER", "app_user")
    MSSQL_APP_PASSWORD: str = os.getenv(
        "MSSQL_APP_PASSWORD", "AppPassword123!")
    MSSQL_SA_PASSWORD: str = os.getenv(
        "MSSQL_SA_PASSWORD", "YourStrongPassword123!")

    # Role-specific credentials
    MSSQL_PGV_USER: str = os.getenv("MSSQL_PGV_USER", "pgv_user")
    MSSQL_PGV_PASSWORD: str = os.getenv("MSSQL_PGV_PASSWORD", "PGV@123456")
    MSSQL_KHOA_USER: str = os.getenv("MSSQL_KHOA_USER", "khoa_user")
    MSSQL_KHOA_PASSWORD: str = os.getenv("MSSQL_KHOA_PASSWORD", "KHOA@123456")
    MSSQL_SV_USER: str = os.getenv("MSSQL_SV_USER", "sv_user")
    MSSQL_SV_PASSWORD: str = os.getenv("MSSQL_SV_PASSWORD", "SV@123456")

    # Database connection strings
    ODBC_CONNECTION_STRING: str = f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={DB_HOST},{DB_PORT};DATABASE={DB_NAME};UID={MSSQL_APP_USER};PWD={MSSQL_APP_PASSWORD};TrustServerCertificate=yes;Connection Timeout=30;"
    SA_ODBC_CONNECTION_STRING: str = f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={DB_HOST},{DB_PORT};UID=sa;PWD={MSSQL_SA_PASSWORD};TrustServerCertificate=yes;Connection Timeout=30;"

    # API configuration
    CORS_ORIGINS: list = ["*"]

    # Execution environment
    IS_MACOS: bool = platform.system() == "Darwin"


@lru_cache()
def get_settings() -> Settings:
    """Get cached application settings."""
    return Settings()
