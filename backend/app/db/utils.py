import os
import sys
import pyodbc
import platform
import subprocess
from pathlib import Path
from app.core.config import get_settings
from app.core.logger import setup_logger
from app.db.database import execute_sql_in_docker

# Setup logger
logger = setup_logger("db_utils")

settings = get_settings()

def reset_database():
    """
    Reset the database using multiple SQL scripts in foundation directory.
    
    Raises:
        FileNotFoundError: If foundation directory or SQL files not found
        Exception: If database reset fails
    """
    try:
        logger.info("Resetting database...")

        # First, try to force disconnect any existing connections
        logger.info("Force disconnecting any active database connections...")
        try:
            force_disconnect_sql = f"""
            IF EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = '{settings.DB_NAME}')
            BEGIN
                ALTER DATABASE [{settings.DB_NAME}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
                DROP DATABASE [{settings.DB_NAME}];
            END
            """
            execute_sql_in_docker(force_disconnect_sql)
            logger.info("Successfully disconnected and dropped existing database")
        except Exception as e:
            logger.warning(f"Could not force disconnect (database may not exist): {e}")

        # Path to the foundation directory
        backend_dir = Path(__file__).resolve().parents[2]  # backend/
        foundation_dir = backend_dir.parents[0] / "database" / "01-foundation"

        if not foundation_dir.exists():
            logger.error(f"Foundation directory not found at {foundation_dir}")
            raise FileNotFoundError(f"Foundation directory not found at {foundation_dir}")

        logger.info(f"Using foundation directory: {foundation_dir}")

        # Get all SQL files in order (01-*, 02-*, etc.)
        sql_files = sorted([f for f in foundation_dir.glob("*.sql") 
                          if f.name.startswith(("01-", "02-", "03-", "04-"))])

        if not sql_files:
            logger.error("No SQL foundation files found")
            raise FileNotFoundError("No SQL foundation files found in foundation directory")

        logger.info(f"Found {len(sql_files)} SQL files to execute")

        # On macOS, use Docker exec method for better compatibility
        if settings.IS_MACOS:
            logger.info("Using Docker exec method for database reset on macOS")

            # Execute each SQL file using Docker exec
            for sql_file in sql_files:
                logger.info(f"Executing SQL file via Docker: {sql_file.name}")

                try:
                    # Read the SQL script
                    with open(sql_file, 'r', encoding='utf-8') as file:
                        sql_script = file.read()

                    # Replace variables with environment values
                    sql_script = sql_script.replace('$(DB_NAME)', settings.DB_NAME)
                    sql_script = sql_script.replace('$(MSSQL_APP_USER)', settings.MSSQL_APP_USER)
                    sql_script = sql_script.replace('$(MSSQL_APP_PASSWORD)', settings.MSSQL_APP_PASSWORD)

                    # Write script to temp file in container
                    temp_file = f"/tmp/{sql_file.name}"

                    # Copy script to container
                    copy_cmd = f"docker exec -i {settings.DB_CONTAINER_NAME} bash -c 'cat > {temp_file}'"

                    copy_result = subprocess.run(
                        copy_cmd, shell=True, input=sql_script, text=True, capture_output=True)
                    if copy_result.returncode != 0:
                        logger.error(f"Failed to copy script to container: {copy_result.stderr}")
                        raise Exception(f"Failed to copy script: {copy_result.stderr}")

                    # Execute the script in container
                    exec_cmd = f"docker exec {settings.DB_CONTAINER_NAME} /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P '{settings.MSSQL_SA_PASSWORD}' -C -i {temp_file}"

                    exec_result = subprocess.run(exec_cmd, shell=True, capture_output=True, text=True)
                    if exec_result.returncode != 0:
                        logger.error(f"Failed to execute {sql_file.name}: {exec_result.stderr}")
                        raise Exception(f"SQL execution failed: {exec_result.stderr}")

                    logger.info(f"Successfully executed {sql_file.name} via Docker")

                    # Clean up temp file
                    cleanup_cmd = f"docker exec {settings.DB_CONTAINER_NAME} rm -f {temp_file}"
                    subprocess.run(cleanup_cmd, shell=True)

                except Exception as e:
                    logger.error(f"Error with {sql_file.name}: {e}")
                    raise
        else:
            # Traditional ODBC connection for non-macOS systems
            logger.info("Using ODBC connection for database reset")

            # Connect as SA
            logger.info("Connecting to SQL Server as sa...")
            try:
                conn = pyodbc.connect(settings.SA_ODBC_CONNECTION_STRING)
                logger.info("Successfully connected to SQL Server as sa")
            except pyodbc.Error as e:
                logger.error(f"Failed to connect to SQL Server as sa: {e}")
                raise

            cursor = conn.cursor()

            # Execute each SQL file in order
            for sql_file in sql_files:
                logger.info(f"Executing SQL file: {sql_file.name}")

                try:
                    # Read the SQL script
                    with open(sql_file, 'r', encoding='utf-8') as file:
                        sql_script = file.read()

                    # Replace variables with environment values
                    sql_script = sql_script.replace('$(DB_NAME)', settings.DB_NAME)
                    sql_script = sql_script.replace('$(MSSQL_APP_USER)', settings.MSSQL_APP_USER)
                    sql_script = sql_script.replace('$(MSSQL_APP_PASSWORD)', settings.MSSQL_APP_PASSWORD)

                    # Execute the entire script (no GO splitting needed)
                    cursor.execute(sql_script)
                    conn.commit()
                    logger.info(f"Successfully executed {sql_file.name}")

                except pyodbc.Error as e:
                    logger.error(f"Error executing {sql_file.name}: {e}")
                    conn.rollback()
                    raise
                except Exception as e:
                    logger.error(f"Unexpected error with {sql_file.name}: {e}")
                    conn.rollback()
                    raise

            cursor.close()
            conn.close()

        logger.info("Database reset completed successfully.")
    except Exception as e:
        logger.error(f"Database reset failed: {e}")
        raise 