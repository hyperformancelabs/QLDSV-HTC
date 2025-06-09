import pyodbc
from fastapi import APIRouter, HTTPException
from app.core.config import get_settings
from app.core.logger import setup_logger
from app.db.database import execute_sql_in_docker

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
    # If on macOS, try Docker exec method first for better compatibility
    if settings.IS_MACOS:
        try:
            version = execute_sql_in_docker("SELECT @@VERSION", timeout=10)
            
            return {
                "status": "healthy",
                "database": {
                    "connected": True,
                    "version": version,
                    "connection_method": "docker_exec"
                },
                "note": "Using Docker exec method for database connection on macOS"
            }
        except Exception as docker_err:
            logger.error(f"Health check via Docker exec failed: {docker_err}")
            # Fall back to ODBC on failure
    
    # Try direct ODBC connection if not macOS or Docker exec failed
    try:
        conn = pyodbc.connect(settings.ODBC_CONNECTION_STRING)
        cursor = conn.cursor()
        cursor.execute("SELECT @@VERSION")
        version = cursor.fetchone()[0]
        cursor.close()
        conn.close()

        return {
            "status": "healthy",
            "database": {
                "connected": True,
                "version": version,
                "connection_method": "odbc"
            }
        }
    except Exception as e:
        logger.error(f"Health check via ODBC failed: {e}")
        error_str = str(e)

        # If Docker exec failed and this is macOS, we've already logged the error
        # If not macOS or we didn't try Docker exec yet, try it now as fallback
        if not settings.IS_MACOS:
            try:
                version = execute_sql_in_docker("SELECT @@VERSION")
                
                return {
                    "status": "healthy",
                    "database": {
                        "connected": True,
                        "version": version,
                        "connection_method": "docker_exec_fallback"
                    },
                    "note": "Using Docker exec method as ODBC fallback"
                }
            except Exception as docker_err:
                logger.error(f"Health check via Docker fallback failed: {docker_err}")

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
        # For macOS, use Docker exec method
        if settings.IS_MACOS:
            try:
                version = execute_sql_in_docker("SELECT @@VERSION")
                
                return {
                    "status": "success",
                    "message": "Successfully connected as SA user via Docker exec",
                    "version": version
                }
            except Exception as e:
                logger.error(f"SA connection test via Docker exec failed: {e}")
                return {
                    "status": "error",
                    "message": f"Failed to connect as SA user via Docker exec: {str(e)}"
                }
        
        # For non-macOS, try ODBC
        conn = pyodbc.connect(settings.SA_ODBC_CONNECTION_STRING)
        cursor = conn.cursor()
        cursor.execute("SELECT @@VERSION")
        version = cursor.fetchone()[0]
        cursor.close()
        conn.close()

        return {
            "status": "success",
            "message": "Successfully connected as SA user via ODBC",
            "version": version
        }
    except Exception as e:
        logger.error(f"SA connection test via ODBC failed: {e}")
        return {
            "status": "error",
            "message": f"Failed to connect as SA user via ODBC: {str(e)}"
        } 