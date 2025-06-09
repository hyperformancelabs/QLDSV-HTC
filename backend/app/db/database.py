import os
import pyodbc
import subprocess
import platform
from fastapi import HTTPException
from app.core.config import get_settings
from app.core.logger import setup_logger

# Setup logger
logger = setup_logger("database")

settings = get_settings()

def get_db_connection():
    """
    Create and return a database connection.
    
    Returns:
        A pyodbc connection object
        
    Raises:
        HTTPException: If connection fails
    """
    try:
        conn = pyodbc.connect(settings.ODBC_CONNECTION_STRING)
        return conn
    except pyodbc.Error as e:
        logger.error(f"Database connection error: {e}")
        raise HTTPException(status_code=500, detail=f"Database connection error: {str(e)}")

def execute_sql_in_docker(sql_query, database=None, timeout=10):
    """
    Execute SQL directly in Docker container, bypassing ODBC.
    
    Args:
        sql_query: The SQL query to execute
        database: Optional database name to connect to
        timeout: Command timeout in seconds
        
    Returns:
        The query result as text
        
    Raises:
        Exception: If SQL execution fails
    """
    try:
        db_param = f"-d {database}" if database else ""
        container_name = settings.DB_CONTAINER_NAME
        password = settings.MSSQL_SA_PASSWORD.replace("'", "'\\''")  # Escape single quotes for shell

        cmd = f"docker exec -i {container_name} /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P '{password}' -C {db_param} -Q \"{sql_query}\" -h-1 -s\",\" -W -w 999 -t {timeout}"
        logger.debug(f"Executing SQL in Docker: {cmd}")

        result = subprocess.run(
            cmd, shell=True, capture_output=True, text=True
        )
        if result.returncode != 0:
            logger.error(f"SQL execution failed: {result.stderr}")
            raise Exception(f"SQL execution error: {result.stderr}")

        return result.stdout.strip()
    except Exception as e:
        logger.error(f"Error executing SQL in Docker: {e}")
        raise 