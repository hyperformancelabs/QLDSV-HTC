import os
import sys
from pathlib import Path
from app.core.config import get_settings
from app.core.logger import setup_logger
from app.db import execute_sql_query, execute_sql_file

# Setup logger
logger = setup_logger("db_utils")

settings = get_settings()


def reset_database():
    """
    Reset the database using multiple SQL scripts from all database directories.

    Database targeting strategy:
    - Foundation, Schema, Security, Backup: Run on 'master' database (system-level operations)
    - Data, Functions, Procedures, Views, Triggers: Run on target database (business logic)

    Raises:
        FileNotFoundError: If database directory or SQL files not found
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
            # Force disconnect should run on master database
            execute_sql_query(force_disconnect_sql, database="master")
            logger.info(
                "Successfully disconnected and dropped existing database")
        except Exception as e:
            logger.warning(
                f"Could not force disconnect (database may not exist): {e}")

        # Path to the database directory
        backend_dir = Path(__file__).resolve().parents[2]  # backend/
        database_dir = backend_dir.parents[0] / "database"

        if not database_dir.exists():
            logger.error(f"Database directory not found at {database_dir}")
            raise FileNotFoundError(
                f"Database directory not found at {database_dir}")

        logger.info(f"Using database directory: {database_dir}")

        # Define which directories should run on which database
        master_database_dirs = [
            "01-foundation",
            "02-schema",
            "03-security",
            "04-backup"
        ]

        target_database_dirs = [
            "05-data",
            "06-functions",
            "07-procedures",
            "08-views",
            "09-triggers"
        ]

        # Process directories in numerical order
        all_dirs = sorted([d for d in database_dir.iterdir()
                          if d.is_dir() and d.name.startswith(('01-', '02-', '03-', '04-', '05-', '06-', '07-', '08-', '09-'))])

        if not all_dirs:
            logger.error("No database directories found")
            raise FileNotFoundError("No database directories found")

        logger.info(f"Found {len(all_dirs)} database directories to process")

        total_files_executed = 0

        # Process each directory
        for db_dir in all_dirs:
            dir_name = db_dir.name
            logger.info(f"Processing directory: {dir_name}")

            # Get SQL files with XX-... pattern only (XX = 2 digits)
            import re
            sql_files = sorted([f for f in db_dir.glob("*.sql")
                                if re.match(r'^\d{2}-.*\.sql$', f.name)])

            if not sql_files:
                logger.info(f"No SQL files found in {dir_name}, skipping...")
                continue

            logger.info(f"Found {len(sql_files)} SQL files in {dir_name}")

            # Determine target database
            if dir_name in master_database_dirs:
                target_db = "master"
                logger.info(
                    f"Directory {dir_name} will run on MASTER database")
            elif dir_name in target_database_dirs:
                target_db = settings.DB_NAME
                logger.info(
                    f"Directory {dir_name} will run on {settings.DB_NAME} database")
            else:
                # Fallback logic for any new directories
                if dir_name.startswith(('01-', '02-', '03-', '04-')):
                    target_db = "master"
                    logger.info(
                        f"Directory {dir_name} (fallback) will run on MASTER database")
                else:
                    target_db = settings.DB_NAME
                    logger.info(
                        f"Directory {dir_name} (fallback) will run on {settings.DB_NAME} database")

            # Execute each SQL file in the directory
            for sql_file in sql_files:
                logger.info(
                    f"Executing SQL file: {sql_file.name} on {target_db} database")

                try:
                    result = execute_sql_file(sql_file, database=target_db)
                    logger.info(
                        f"Successfully executed {sql_file.name} on {target_db} database")
                    total_files_executed += 1

                    # Log result if it contains useful information
                    if result and "successfully" in result.lower():
                        logger.debug(
                            f"Result from {sql_file.name}: {result[:200]}...")

                except Exception as e:
                    logger.error(
                        f"Error executing {sql_file.name} on {target_db}: {e}")
                    raise

        logger.info(
            f"Database reset completed successfully. Total files executed: {total_files_executed}")

    except Exception as e:
        logger.error(f"Database reset failed: {e}")
        raise
