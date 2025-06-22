"""Health check endpoints."""

import logging
import os
from fastapi import APIRouter, HTTPException
from typing import Dict, Any

from app.db.connection import check_db_health, get_connection, normalize_driver_name
from app.core.config import APP_SETTINGS

router = APIRouter()
logger = logging.getLogger("app.api.health")


def get_connection_info() -> Dict[str, str]:
    """Return standardized connection info for responses."""
    return {
        "host": f"{APP_SETTINGS.DB_HOST}:{APP_SETTINGS.DB_PORT}",
        "driver": normalize_driver_name(APP_SETTINGS.DB_DRIVER),
        "user": "sa"
    }


@router.get("/health", summary="Health check", tags=["Health"])
async def health_check() -> Dict[str, Any]:
    """
    Check the health of the application and its dependencies.

    Returns:
        Dict[str, Any]: Health status of the application and its components
    """
    logger.info(
        f"DB Connection settings - HOST: {APP_SETTINGS.DB_HOST}, PORT: {APP_SETTINGS.DB_PORT}, DRIVER: {APP_SETTINGS.DB_DRIVER}")

    app_status = {"status": "healthy", "message": "Application is running"}

    # Check database health
    db_status = check_db_health()

    # Determine overall status
    overall_status = "healthy" if db_status["status"] == "healthy" else "unhealthy"

    if overall_status == "unhealthy":
        logger.warning(f"Health check failed: {db_status['message']}")

    return {
        "status": overall_status,
        "application": app_status,
        "database": db_status
    }


@router.get("/health/db", summary="Database health check", tags=["Health"])
async def db_health_check() -> Dict[str, Any]:
    """
    Check the health of the database connection.

    Returns:
        Dict[str, Any]: Health status of the database connection
    """
    db_status = check_db_health()

    if db_status["status"] == "unhealthy":
        logger.warning(f"Database health check failed: {db_status['message']}")
        raise HTTPException(status_code=503, detail=db_status)

    return db_status


@router.get("/health/db/detailed", summary="Detailed database health check", tags=["Health"])
async def detailed_db_health_check() -> Dict[str, Any]:
    """
    Perform a detailed health check of the database.

    Returns:
        Dict[str, Any]: Detailed health status of the database
    """
    try:
        # Log connection settings for debugging
        logger.info(
            f"DB Connection settings (detailed) - HOST: {APP_SETTINGS.DB_HOST}, PORT: {APP_SETTINGS.DB_PORT}, DRIVER: {APP_SETTINGS.DB_DRIVER}")

        conn = get_connection("master")
        cursor = conn.cursor()

        # Basic database information
        cursor.execute("SELECT @@VERSION AS version")
        version = cursor.fetchone()[0]

        # Get database sizes
        cursor.execute("""
            SELECT 
                DB_NAME(database_id) AS database_name,
                CAST(SUM(size) * 8 / 1024.0 AS DECIMAL(10, 2)) AS size_mb
            FROM sys.master_files
            GROUP BY database_id
            ORDER BY database_name
        """)
        db_sizes = [{"name": row[0], "size_mb": row[1]}
                    for row in cursor.fetchall()]

        # Check QLDSV_HTC tables
        cursor.execute("SELECT DB_NAME() AS current_db")
        current_db = cursor.fetchone()[0]

        # Switch to QLDSV_HTC database if not already there
        db_name = APP_SETTINGS.DB_NAME
        if current_db != db_name:
            conn.close()
            conn = get_connection(db_name)
            cursor = conn.cursor()

        # Get table counts
        cursor.execute("""
            SELECT 
                t.name AS table_name,
                p.rows AS row_count
            FROM sys.tables t
            INNER JOIN sys.indexes i ON t.object_id = i.object_id
            INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
            WHERE i.index_id < 2  -- Only clustered index or heap
            ORDER BY t.name
        """)
        tables = [{"name": row[0], "row_count": row[1]}
                  for row in cursor.fetchall()]

        # Get stored procedures
        cursor.execute("""
            SELECT name 
            FROM sys.procedures
            ORDER BY name
        """)
        procedures = [row[0] for row in cursor.fetchall()]

        conn.close()

        return {
            "status": "healthy",
            "message": "Database connection successful",
            "version": version,
            "databases": db_sizes,
            "tables": tables,
            "procedures": procedures,
            "connection": get_connection_info()
        }
    except Exception as e:
        logger.error(f"Detailed database health check failed: {str(e)}")
        return {
            "status": "unhealthy",
            "message": f"Database detailed check failed: {str(e)}",
            "connection": get_connection_info()
        }
