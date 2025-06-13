import os
import logging
from typing import Dict, Any, Optional
from functools import lru_cache
from dotenv import load_dotenv
import platform
import secrets

# Load environment variables WITH interpolation support
load_dotenv(override=True)

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


def _get_env(key: str, default: Optional[str] = None, required: bool = False) -> str:
    """Helper lấy biến môi trường, cắt bỏ dấu ngoặc kép nếu có và kiểm tra tồn tại.

    Args:
        key (str): Tên biến môi trường
        default (Optional[str]): Giá trị mặc định (nếu không yêu cầu)
        required (bool): Nếu True, raise Exception nếu không tìm thấy

    Returns:
        str: Giá trị biến môi trường đã được strip bỏ dấu quote ngoài (nếu có)
    """
    val = os.getenv(key, default)

    if required and (val is None or val == ""):
        raise EnvironmentError(f"Missing required environment variable: {key}")

    if val and len(val) >= 2 and ((val.startswith("'") and val.endswith("'")) or (val.startswith('"') and val.endswith('"'))):
        val = val[1:-1]
    return val


class Settings:  # noqa: R0903
    """Application settings loaded from environment variables."""

    # PROJECT META
    PROJECT_NAME: str = _get_env("PROJECT_NAME", "QLDSV-HTC")
    PROJECT_VERSION: str = _get_env("PROJECT_VERSION", "1.0.0")
    PROJECT_DESCRIPTION: str = "API for QLDSV-HTC (Quản lý điểm sinh viên hệ tín chỉ)"

    # API CONFIGURATION
    API_PREFIX: str = _get_env("API_PREFIX", "/api/v1")
    AUTH_PREFIX: str = _get_env("AUTH_PREFIX", "/auth")
    SESSION_MAX_AGE: int = int(_get_env("SESSION_MAX_AGE", "3600"))
    SESSION_SECRET: str = _get_env("SESSION_SECRET", secrets.token_hex(32))

    # DATABASE CORE CONFIG
    DB_HOST: str = _get_env("DB_HOST", "localhost")
    DB_PORT: str = _get_env("DB_PORT", "1434")
    DB_NAME: str = _get_env("DB_NAME", "QLDSV_HTC")
    DB_CONTAINER_NAME: str = _get_env("DB_CONTAINER_NAME", "qldsv-sqlserver")
    DB_DEFAULT_USER: str = _get_env("DB_DEFAULT_USER", "app_user")

    # CREDENTIALS (required)
    MSSQL_SA_PASSWORD: str = _get_env("MSSQL_SA_PASSWORD", required=True)
    MSSQL_APP_USER: str = _get_env("MSSQL_APP_USER", "app_user")
    MSSQL_APP_PASSWORD: str = _get_env("MSSQL_APP_PASSWORD", required=True)

    # ROLE-SPECIFIC (optional but encouraged)
    MSSQL_PGV_USER: str = _get_env("MSSQL_PGV_USER", "pgv_user")
    MSSQL_PGV_PASSWORD: str = _get_env("MSSQL_PGV_PASSWORD", required=True)
    MSSQL_KHOA_USER: str = _get_env("MSSQL_KHOA_USER", "khoa_user")
    MSSQL_KHOA_PASSWORD: str = _get_env("MSSQL_KHOA_PASSWORD", required=True)
    MSSQL_SV_USER: str = _get_env("MSSQL_SV_USER", "sv_user")
    MSSQL_SV_PASSWORD: str = _get_env("MSSQL_SV_PASSWORD", required=True)

    # DYNAMIC USER PREFIX for future scaling
    USER_PREFIX: str = "MSSQL_"  # Pattern: MSSQL_<USERNAME>_PASSWORD

    # Database connection strings (built lazily in __post_init__)
    ODBC_CONNECTION_STRING: str = ""
    SA_ODBC_CONNECTION_STRING: str = ""

    # API / PLATFORM
    CORS_ORIGINS: list = ["*"]
    IS_MACOS: bool = platform.system() == "Darwin"

    # DEVELOPMENT / FALLBACK SETTINGS
    ENABLE_TEACHER_FALLBACK_AUTH: bool = _get_env(
        "ENABLE_TEACHER_FALLBACK_AUTH", "true").lower() == "true"
    DEVELOPMENT_MODE: bool = _get_env(
        "DEVELOPMENT_MODE", "true").lower() == "true"

    def __post_init__(self):
        # Build connection strings after variables exist
        self.ODBC_CONNECTION_STRING = (
            f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={self.DB_HOST},{self.DB_PORT};DATABASE={self.DB_NAME};"
            f"UID={self.MSSQL_APP_USER};PWD={self.MSSQL_APP_PASSWORD};TrustServerCertificate=yes;Connection Timeout=30;Encrypt=yes;"
        )
        self.SA_ODBC_CONNECTION_STRING = (
            f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={self.DB_HOST},{self.DB_PORT};"
            f"UID=sa;PWD={self.MSSQL_SA_PASSWORD};TrustServerCertificate=yes;Connection Timeout=30;Encrypt=yes;"
        )

        # Debug logging of important vars (masking passwords)
        logger.debug(
            {
                "DB_HOST": self.DB_HOST,
                "DB_PORT": self.DB_PORT,
                "DB_NAME": self.DB_NAME,
                "SA_PASS_LEN": len(self.MSSQL_SA_PASSWORD),
                "APP_USER": self.MSSQL_APP_USER,
                "IS_MACOS": self.IS_MACOS,
            }
        )

    # Utility to fetch dynamic user passwords
    def get_dynamic_password(self, username: str) -> Optional[str]:
        env_key = f"{self.USER_PREFIX}{username.upper()}_PASSWORD"
        return os.getenv(env_key)


@lru_cache()
def get_settings() -> Settings:  # noqa: D401
    """Return cached Settings instance (loads env only once)."""
    settings = Settings()
    settings.__post_init__()
    return settings
