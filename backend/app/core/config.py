"""Application settings and environment loading."""

from __future__ import annotations

import os
import sys
import logging
from pathlib import Path
from typing import Set, Dict, Any, Optional

logger = logging.getLogger("app.core.config")


class MissingEnvironmentVariable(Exception):
    """Exception raised when a required environment variable is missing."""
    pass


def getenv_strict(key: str, default: Optional[str] = None) -> str:
    """Get an environment variable or raise an exception if it's not set and no default provided."""
    value = os.getenv(key)
    if value is None:
        if default is not None:
            return default
        raise MissingEnvironmentVariable(
            f"Required environment variable '{key}' is not set")
    return value


# Paths
PROJECT_ROOT: Path = Path(__file__).resolve().parents[3]
BACKEND_DIR: Path = PROJECT_ROOT / "backend"

# Load env files
ROOT_ENV: Path = PROJECT_ROOT / ".env"
BACKEND_ENV: Path = BACKEND_DIR / ".env"


class Settings:
    """Singleton class for application settings."""
    _instance = None
    _initialized = False

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(Settings, cls).__new__(cls)
        return cls._instance

    def __init__(self):
        if not self._initialized:
            # Load environment variables
            from dotenv import load_dotenv

            # Log environment file paths
            logger.info(
                f"ROOT_ENV path: {ROOT_ENV} (exists: {ROOT_ENV.exists()})")
            logger.info(
                f"BACKEND_ENV path: {BACKEND_ENV} (exists: {BACKEND_ENV.exists()})")

            if ROOT_ENV.exists():
                load_dotenv(ROOT_ENV, override=False)
                logger.info(f"Loaded environment variables from {ROOT_ENV}")
            if BACKEND_ENV.exists():
                load_dotenv(BACKEND_ENV, override=True)
                logger.info(f"Loaded environment variables from {BACKEND_ENV}")

            # Core application settings
            self.APP_TITLE = getenv_strict("APP_TITLE")
            self.APP_DESCRIPTION = getenv_strict("APP_DESCRIPTION")
            self.APP_VERSION = getenv_strict("APP_VERSION")

            self.APP_HOST = getenv_strict("APP_HOST")
            self.APP_PORT = int(getenv_strict("APP_PORT"))
            self.APP_RELOAD = getenv_strict("APP_RELOAD").lower() in {
                "1", "true", "yes"}

            # Database settings
            self.DB_HOST = getenv_strict("DB_HOST")
            self.DB_PORT = getenv_strict("DB_PORT")
            self.DB_NAME = getenv_strict("DB_NAME")
            self.DB_DRIVER = getenv_strict("DB_DRIVER")
            self.MSSQL_SA_PASSWORD = getenv_strict("MSSQL_SA_PASSWORD")
            self.MSSQL_APP_USER = getenv_strict("MSSQL_APP_USER")
            self.MSSQL_APP_PASSWORD = getenv_strict("MSSQL_APP_PASSWORD")
            self.MSSQL_PGV_USER = getenv_strict("MSSQL_PGV_USER")
            self.MSSQL_PGV_PASSWORD = getenv_strict("MSSQL_PGV_PASSWORD")
            self.MSSQL_KHOA_USER = getenv_strict("MSSQL_KHOA_USER")
            self.MSSQL_KHOA_PASSWORD = getenv_strict("MSSQL_KHOA_PASSWORD")
            self.MSSQL_SV_USER = getenv_strict("MSSQL_SV_USER")
            self.MSSQL_SV_PASSWORD = getenv_strict("MSSQL_SV_PASSWORD")

            # API settings
            self.API_PREFIX = getenv_strict("API_PREFIX")

            # Logging settings
            self.LOG_LEVEL = getenv_strict("LOG_LEVEL")

            # Project info
            self.PROJECT_NAME = getenv_strict("PROJECT_NAME")

            self._initialized = True

    def __getitem__(self, key):
        """Allow dictionary-like access to settings."""
        return getattr(self, key)

    def get(self, key, default=None):
        """Get a setting value with a default."""
        return getattr(self, key, default)

    def as_dict(self) -> Dict[str, Any]:
        """Return all settings as a dictionary."""
        return {k: v for k, v in self.__dict__.items() if not k.startswith('_')}


def load_environment() -> Dict[str, Any]:
    """Load environment variables from .env files."""
    settings = Settings()
    return settings.as_dict()


# Create a singleton instance
APP_SETTINGS = Settings()


def verify_cwd() -> None:
    """Ensure the backend is executed from project root or backend directory."""
    allowed_dirs: Set[Path] = {PROJECT_ROOT, BACKEND_DIR}
    cwd = Path.cwd().resolve()

    if cwd not in allowed_dirs:
        print(
            "\n".join(
                [
                    "[QLDSV-HTC] ❌  Backend must be started from the project root.",
                    f"  Detected cwd: {cwd}",
                    f"  Expected   : {PROJECT_ROOT}",
                    "",
                    "Hint: run `bash ./scripts/start-backend.sh` or `cd` to project root before executing the server.",
                ]
            ),
            file=sys.stderr,
        )
        sys.exit(1)
