import pyodbc
import subprocess
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
    # Try using the unified SQL executor with default SA user
    try:
        version = execute_sql_query("SELECT @@VERSION")

        return {
            "status": "healthy",
            "database": {
                "connected": True,
                "version": version,
                "connection_method": "unified_executor",
                "user": "sa"
            },
            "note": "Using unified SQL executor with automatic method selection"
        }
    except Exception as e:
        logger.error(f"Health check via SA user failed: {e}")
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
            # Try with PGV user as backup
            try:
                pgv_version = execute_sql_query(
                    "SELECT @@VERSION", user_type="pgv_user")
                return {
                    "status": "healthy",
                    "database": {
                        "connected": True,
                        "version": pgv_version,
                        "connection_method": "unified_executor",
                        "user": "pgv_user",
                        "note": "SA connection failed, but connected with PGV user"
                    }
                }
            except Exception as pgv_error:
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
        version = execute_sql_query("SELECT @@VERSION", user_type="sa")

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


@router.get("/test-app-user-connection")
async def test_app_user_connection():
    """
    Test connection as application user.

    Returns:
        dict: Connection status information
    """
    try:
        # Use the unified executor with app_user credentials
        version = execute_sql_query("SELECT @@VERSION", user_type="app_user")

        return {
            "status": "success",
            "message": "Successfully connected as application user via unified executor",
            "version": version
        }
    except Exception as e:
        logger.error(
            f"App user connection test via unified executor failed: {e}")
        return {
            "status": "error",
            "message": f"Failed to connect as application user via unified executor: {str(e)}"
        }


@router.get("/test-pgv-connection")
async def test_pgv_connection():
    """
    Test connection as PGV (Phòng Giáo Vụ) user.

    Returns:
        dict: Connection status information
    """
    try:
        # Use the unified executor with pgv_user credentials
        version = execute_sql_query("SELECT @@VERSION", user_type="pgv_user")

        return {
            "status": "success",
            "message": "Successfully connected as PGV user via unified executor",
            "version": version
        }
    except Exception as e:
        logger.error(
            f"PGV user connection test via unified executor failed: {e}")
        return {
            "status": "error",
            "message": f"Failed to connect as PGV user via unified executor: {str(e)}"
        }


@router.get("/test-khoa-connection")
async def test_khoa_connection():
    """
    Test connection as Khoa user.

    Returns:
        dict: Connection status information
    """
    try:
        # Use the unified executor with khoa_user credentials
        version = execute_sql_query("SELECT @@VERSION", user_type="khoa_user")

        return {
            "status": "success",
            "message": "Successfully connected as Khoa user via unified executor",
            "version": version
        }
    except Exception as e:
        logger.error(
            f"Khoa user connection test via unified executor failed: {e}")
        return {
            "status": "error",
            "message": f"Failed to connect as Khoa user via unified executor: {str(e)}"
        }


@router.get("/test-sv-connection")
async def test_sv_connection():
    """
    Test connection as SV (Sinh Viên) user.

    Returns:
        dict: Connection status information
    """
    try:
        # Use the unified executor with sv_user credentials
        version = execute_sql_query("SELECT @@VERSION", user_type="sv_user")

        return {
            "status": "success",
            "message": "Successfully connected as SV user via unified executor",
            "version": version
        }
    except Exception as e:
        logger.error(
            f"SV user connection test via unified executor failed: {e}")
        return {
            "status": "error",
            "message": f"Failed to connect as SV user via unified executor: {str(e)}"
        }


@router.get("/test-all-connections")
async def test_all_connections():
    """
    Test connections for all user types with both connection methods.

    Returns:
        dict: Connection status information for all users
    """
    result = {
        "status": "success",
        "connections": {},
        "config": {
            "db_host": settings.DB_HOST,
            "db_port": settings.DB_PORT,
            "db_name": settings.DB_NAME,
            "odbc_driver": "ODBC Driver 18 for SQL Server",
            "is_macos": settings.IS_MACOS
        },
        "docker": {
            "container_name": settings.DB_CONTAINER_NAME
        }
    }

    # Test direct Docker SQL command to verify SQL Server is running
    try:
        cmd = f"docker exec -i {settings.DB_CONTAINER_NAME} /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P '{settings.MSSQL_SA_PASSWORD}' -C -Q \"SELECT @@VERSION\""
        docker_result = subprocess.run(
            cmd, shell=True, capture_output=True, text=True)

        if docker_result.returncode == 0:
            result["docker"]["status"] = "running"
            result["docker"]["version"] = docker_result.stdout.strip()
        else:
            result["docker"]["status"] = "error"
            result["docker"]["error"] = docker_result.stderr.strip()
    except Exception as e:
        result["docker"]["status"] = "error"
        result["docker"]["error"] = str(e)

    # List of users to test
    users = [
        {"type": "sa", "name": "sa", "password": settings.MSSQL_SA_PASSWORD},
        {"type": "app_user", "name": settings.MSSQL_APP_USER,
            "password": settings.MSSQL_APP_PASSWORD},
        {"type": "pgv_user", "name": settings.MSSQL_PGV_USER,
            "password": settings.MSSQL_PGV_PASSWORD},
        {"type": "khoa_user", "name": settings.MSSQL_KHOA_USER,
            "password": settings.MSSQL_KHOA_PASSWORD},
        {"type": "sv_user", "name": settings.MSSQL_SV_USER,
            "password": settings.MSSQL_SV_PASSWORD}
    ]

    # Test each user
    for user in users:
        result["connections"][user["type"]] = {
            "username": user["name"],
            "methods": {}
        }

        # Test via unified executor
        try:
            unified_version = execute_sql_query(
                "SELECT @@VERSION", user_type=user["type"])
            result["connections"][user["type"]]["methods"]["unified"] = {
                "status": "success",
                "version": unified_version
            }
        except Exception as e:
            result["connections"][user["type"]]["methods"]["unified"] = {
                "status": "error",
                "error": str(e)
            }
            result["status"] = "partial"

        # Test direct Docker connection
        try:
            docker_cmd = f"docker exec -i {settings.DB_CONTAINER_NAME} /opt/mssql-tools18/bin/sqlcmd -S localhost -U {user['name']} -P '{user['password']}' -C -Q \"SELECT @@VERSION\""
            docker_user_result = subprocess.run(
                docker_cmd, shell=True, capture_output=True, text=True)

            if docker_user_result.returncode == 0:
                result["connections"][user["type"]]["methods"]["direct_docker"] = {
                    "status": "success",
                    "version": docker_user_result.stdout.strip()
                }
            else:
                result["connections"][user["type"]]["methods"]["direct_docker"] = {
                    "status": "error",
                    "error": docker_user_result.stderr.strip()
                }
                result["status"] = "partial"
        except Exception as e:
            result["connections"][user["type"]]["methods"]["direct_docker"] = {
                "status": "error",
                "error": str(e)
            }
            result["status"] = "partial"

        # Test direct ODBC connection (if not on macOS)
        if not settings.IS_MACOS:
            try:
                # Build direct ODBC connection string
                conn_str = (
                    f"DRIVER={{ODBC Driver 18 for SQL Server}};"
                    f"SERVER={settings.DB_HOST},{settings.DB_PORT};"
                    f"DATABASE={settings.DB_NAME};"
                    f"UID={user['name']};"
                    f"PWD={user['password']};"
                    f"TrustServerCertificate=yes;"
                    f"Connection Timeout=30;"
                    f"Encrypt=yes;"
                )

                # Test direct ODBC connection
                conn = pyodbc.connect(conn_str)
                cursor = conn.cursor()
                cursor.execute("SELECT @@VERSION")
                rows = cursor.fetchall()
                direct_odbc_version = rows[0][0] if rows else "Unknown"
                cursor.close()
                conn.close()

                result["connections"][user["type"]]["methods"]["direct_odbc"] = {
                    "status": "success",
                    "version": direct_odbc_version
                }
            except Exception as e:
                result["connections"][user["type"]]["methods"]["direct_odbc"] = {
                    "status": "error",
                    "error": str(e)
                }
                result["status"] = "partial"

    # Add final diagnostics
    result["diagnostics"] = {
        "working_users": [user for user in result["connections"] if result["connections"][user]["methods"]["unified"]["status"] == "success"],
        "failing_users": [user for user in result["connections"] if result["connections"][user]["methods"]["unified"]["status"] == "error"],
    }

    return result
