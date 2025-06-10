import pyodbc
from fastapi import APIRouter, HTTPException
from app.core.config import get_settings
from app.core.logger import setup_logger
from app.db import execute_sql_query

# Setup router
router = APIRouter()

# Setup logger
logger = setup_logger("api.health")

# Get settings
settings = get_settings()


@router.get("/health")
async def health_check():
    """
    Health check endpoint that verifies database connectivity.

    Returns:
        dict: Health status information
    """
    # Try using the unified SQL executor
    try:
        version = execute_sql_query("SELECT @@VERSION")

        return {
            "status": "healthy",
            "database": {
                "connected": True,
                "version": version,
                "connection_method": "unified_executor"
            },
            "note": "Using unified SQL executor with automatic method selection"
        }
    except Exception as e:
        logger.error(f"Health check via unified executor failed: {e}")
        error_str = str(e)

        # Check if the error is related to missing ODBC driver
        if "Can't open lib 'ODBC Driver 18 for SQL Server'" in error_str:
            return {
                "status": "warning",
                "database": {
                    "connected": False,
                    "error": str(e),
                    "message": "ODBC Driver not found. This is expected on macOS development environments. The app can still function for frontend development.",
                    "solution": "For full backend functionality, either install the ODBC driver or use Docker for database operations."
                },
                "api": {
                    "status": "available",
                    "message": "API endpoints are available for frontend development"
                }
            }
        # Check for timeout issues
        elif "timeout" in error_str.lower() or "HYT00" in error_str:
            return {
                "status": "warning",
                "database": {
                    "connected": False,
                    "error": str(e),
                    "message": "Connection timeout. The SQL Server is either not running or not accessible.",
                    "solution": "Make sure the SQL Server container is running and accessible at the configured host and port."
                },
                "api": {
                    "status": "available",
                    "message": "API endpoints are available for frontend development"
                }
            }

        return {
            "status": "unhealthy",
            "database": {
                "connected": False,
                "error": str(e)
            }
        }


@router.get("/test-sa-connection")
async def test_sa_connection():
    """
    Test connection as sa user.

    Returns:
        dict: Connection status information
    """
    try:
        # Use the unified executor - it will automatically choose the best method
        version = execute_sql_query("SELECT @@VERSION")

        return {
            "status": "success",
            "message": "Successfully connected as SA user via unified executor",
            "version": version
        }
    except Exception as e:
        logger.error(f"SA connection test via unified executor failed: {e}")
        return {
            "status": "error",
            "message": f"Failed to connect as SA user via unified executor: {str(e)}"
        }
