"""Database connection utilities."""

import os
import logging
from typing import Dict, Any, List, Optional

import pyodbc
from dotenv import load_dotenv

from app.core.config import APP_SETTINGS

logger = logging.getLogger("app.db.connection")


def get_available_drivers() -> List[str]:
    """Get available ODBC drivers."""
    return pyodbc.drivers()


def normalize_driver_name(driver: str) -> str:
    """Normalize driver name by removing surrounding quotes if present."""
    if driver.startswith('"') and driver.endswith('"'):
        return driver[1:-1]
    return driver


def build_connection_string(
    user: str,
    password: str,
    database: Optional[str] = None,
    timeout: int = 2
) -> str:
    """Build a connection string with the given parameters."""
    db_name = database if database is not None else APP_SETTINGS.DB_NAME
    db_host = APP_SETTINGS.DB_HOST
    db_port = APP_SETTINGS.DB_PORT
    db_driver = normalize_driver_name(APP_SETTINGS.DB_DRIVER)

    return (
        f"DRIVER={{{db_driver}}};"
        f"SERVER={db_host},{db_port};"
        f"DATABASE={db_name};"
        f"UID={user};"
        f"PWD={password};"
        "TrustServerCertificate=yes;"
        f"Connection Timeout={timeout};"
    )


def get_connection_string(database: Optional[str] = None) -> str:
    """Generate a connection string for SQL Server using SA credentials."""
    return build_connection_string("sa", APP_SETTINGS.MSSQL_SA_PASSWORD, database)


def get_connection(database: Optional[str] = None) -> pyodbc.Connection:
    """Get a database connection."""
    connection_string = get_connection_string(database)
    try:
        logger.debug(
            f"Attempting to connect with string: {connection_string.split('PWD=')[0]}PWD=*****")
        return pyodbc.connect(connection_string)
    except Exception as e:
        logger.error(f"Failed to connect to database: {str(e)}")
        logger.error(
            f"Connection string (without password): {connection_string.split('PWD=')[0]}PWD=*****")

        # Check if the driver exists
        available_drivers = get_available_drivers()
        db_driver = normalize_driver_name(APP_SETTINGS.DB_DRIVER)

        if db_driver not in available_drivers:
            logger.error(
                f"Driver '{db_driver}' not found. Available drivers: {available_drivers}")

        raise e


def check_db_health() -> Dict[str, Any]:
    """Check database health and return status information."""
    try:
        conn = get_connection("master")
        cursor = conn.cursor()

        # Check if server is responsive
        cursor.execute("SELECT @@VERSION")
        version = cursor.fetchone()[0]

        # Get list of databases
        cursor.execute("SELECT name FROM sys.databases")
        databases = [row[0] for row in cursor.fetchall()]

        conn.close()

        # Get connection info for response
        host = APP_SETTINGS.DB_HOST
        port = APP_SETTINGS.DB_PORT
        driver = normalize_driver_name(APP_SETTINGS.DB_DRIVER)

        return {
            "status": "healthy",
            "message": "Database connection successful",
            "version": version,
            "databases": databases,
            "connection": {
                "host": f"{host}:{port}",
                "driver": driver,
                "user": "sa"
            }
        }
    except Exception as e:
        logger.error(f"Database health check failed: {str(e)}")

        # Get connection info for response
        host = APP_SETTINGS.DB_HOST
        port = APP_SETTINGS.DB_PORT
        driver = normalize_driver_name(APP_SETTINGS.DB_DRIVER)

        return {
            "status": "unhealthy",
            "message": f"Database connection failed: {str(e)}",
            "connection": {
                "host": f"{host}:{port}",
                "driver": driver,
                "user": "sa"
            }
        }


def get_connection_with_credentials(user: str, password: str, database: Optional[str] = None) -> pyodbc.Connection:
    """Get a database connection using explicit credentials.

    This is primarily used for role-based logins (PGV, KHOA) or the shared
    student login.  Falls back to raising the underlying `pyodbc.Error` if the
    connection cannot be established.
    """
    connection_string = build_connection_string(user, password, database)
    try:
        logger.debug(
            "Attempting to connect with custom credentials: %sPWD=*****",
            connection_string.split("PWD=")[0],
        )
        return pyodbc.connect(connection_string)
    except Exception as exc:
        logger.error("Failed to connect using user '%s': %s", user, str(exc))
        raise
