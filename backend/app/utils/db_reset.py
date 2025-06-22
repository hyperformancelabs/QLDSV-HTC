"""Database reset utilities.

This module provides functions to reset the database by executing SQL scripts
in a predefined order. It handles the preprocessing of SQL files to replace
environment variables and split multi-USE statements into separate files.
"""

import logging
import os
import re
import shutil
import pyodbc
import time
import glob
from pathlib import Path
from typing import List, Dict, Optional, Set, Tuple

from app.core.config import PROJECT_ROOT, APP_SETTINGS
from app.db.connection import normalize_driver_name, build_connection_string

logger = logging.getLogger("app.utils.db_reset")

# Location for compiled SQL files
COMPILED_DIR = PROJECT_ROOT / "database" / "prebuild"


def _get_folder_execution_order() -> List[str]:
    """
    Automatically discover and sort database folders based on numeric prefix.

    Returns:
        List of folder names in the correct execution order
    """
    database_dir = PROJECT_ROOT / "database"
    folders = []

    # Find all folders with numeric prefixes (e.g., 01-foundation, 02-schema, etc.)
    for item in database_dir.iterdir():
        if item.is_dir() and re.match(r'^\d+', item.name):
            folders.append(item.name)

    # Sort folders by their numeric prefix
    folders.sort(key=lambda x: int(re.match(r'^(\d+)', x).group(1)))
    logger.info(f"Discovered folder order: {', '.join(folders)}")

    return folders


def _cleanup_compiled_dir() -> None:
    """
    Clean up the compiled directory before generating new files.
    Creates the directory if it doesn't exist.
    """
    if COMPILED_DIR.exists():
        logger.info(f"Cleaning up compiled directory: {COMPILED_DIR}")
        shutil.rmtree(COMPILED_DIR)

    logger.info(f"Creating compiled directory: {COMPILED_DIR}")
    COMPILED_DIR.mkdir(exist_ok=True)


def _replace_environment_variables(content: str) -> str:
    """
    Replace environment variables in SQL content with their actual values.

    Args:
        content: SQL content with placeholders like $(VAR_NAME)

    Returns:
        SQL content with placeholders replaced by actual values
    """
    # Create mapping of environment variables
    env_map = {k: str(v) for k, v in APP_SETTINGS.as_dict().items()}

    # Replace all $(VAR_NAME) placeholders
    pattern = re.compile(r'\$\(([A-Za-z0-9_]+)\)')

    def replace_match(match):
        var_name = match.group(1)
        if var_name in env_map:
            return env_map[var_name]
        logger.warning(f"Environment variable not found: {var_name}")
        return match.group(0)  # Return the original if not found

    return pattern.sub(replace_match, content)


def _split_by_use_statements(content: str) -> List[Tuple[str, str]]:
    """
    Split SQL content by USE statements.

    Args:
        content: SQL content to split

    Returns:
        List of tuples (database_name, sql_batch)
    """
    # Use regex to match "USE [database_name]" or "USE database_name"
    use_pattern = re.compile(
        r'USE\s+(?:\[([^\]]+)\]|([^\s;]+))\s*;', re.IGNORECASE)

    # Find all USE statements
    matches = list(use_pattern.finditer(content))

    if not matches:
        # Default to master database if no USE statement
        return [("master", content)]

    results = []
    for i, match in enumerate(matches):
        # Get the database name (either from bracketed or unbracketed form)
        db_name = match.group(1) if match.group(1) else match.group(2)

        # Determine batch content
        start_pos = match.start()
        end_pos = matches[i+1].start() if i+1 < len(matches) else len(content)

        # Extract batch content including the USE statement
        batch_content = content[start_pos:end_pos].strip()

        results.append((db_name, batch_content))

    return results


def _get_folder_index(folder_name: str, folder_order: List[str]) -> int:
    """
    Get the correct index for a folder based on execution order.

    Args:
        folder_name: Name of the folder (e.g., '01-foundation')
        folder_order: List of folder names in execution order

    Returns:
        Index in the folder_order list
    """
    try:
        return folder_order.index(folder_name) + 1
    except ValueError:
        # If folder is not in the list, return a high number to place it last
        return 99


def compile_sql_files() -> List[Path]:
    """
    Compile all SQL files in the database directory:
    1. Replace environment variables
    2. Split files by USE statements
    3. Rename with proper prefixes

    Returns:
        List of paths to compiled files in execution order
    """
    # Clean up and create compiled directory
    _cleanup_compiled_dir()

    database_dir = PROJECT_ROOT / "database"
    compiled_files = []

    # Get the folder execution order dynamically
    folder_order = _get_folder_execution_order()

    # Process folders in the correct execution order
    for folder_name in folder_order:
        folder_path = database_dir / folder_name

        if not folder_path.exists() or not folder_path.is_dir():
            logger.warning(f"Folder not found: {folder_name}")
            continue

        # Get folder index in the execution order (1-based)
        folder_index = _get_folder_index(folder_name, folder_order)
        logger.info(
            f"Processing folder: {folder_name} (index: {folder_index})")

        # Get all SQL files in this folder
        sql_files = [f for f in folder_path.iterdir() if f.is_file()
                     and f.suffix.lower() == '.sql']
        sql_files.sort(key=lambda x: x.name)  # Sort by name

        for file_index, file_path in enumerate(sql_files, 1):
            logger.info(f"Compiling file: {file_path.name}")

            try:
                # Read file content
                content = file_path.read_text(encoding='utf-8')

                # Replace environment variables
                content = _replace_environment_variables(content)

                # Split by USE statements
                batches = _split_by_use_statements(content)

                # Extract original file number (if any) from filename
                # Example: 01-create-database.sql -> 01
                original_num_match = re.match(r'^(\d+)', file_path.stem)
                original_num = original_num_match.group(
                    1) if original_num_match else ""

                # Create compiled files
                for batch_index, (db_name, batch_content) in enumerate(batches, 1):
                    # Format: {folder_index:02d}-{original_file_number}-{rest_of_filename}-batch{batch_number}.sql
                    folder_prefix = f"{folder_index:02d}"

                    # Strip the number prefix from the original filename if it exists
                    base_name = file_path.stem
                    if original_num:
                        base_name = base_name[len(original_num):].lstrip('-')

                    # Create filename
                    if len(batches) > 1:
                        filename = f"{folder_prefix}{original_num}-{base_name}-batch{batch_index}.sql"
                    else:
                        filename = f"{folder_prefix}{original_num}-{base_name}.sql"

                    # Create compiled file
                    target_path = COMPILED_DIR / filename
                    target_path.write_text(batch_content, encoding='utf-8')

                    compiled_files.append(target_path)
                    logger.debug(
                        f"Created compiled file: {filename} (DB: {db_name})")

            except Exception as e:
                logger.error(f"Error compiling {file_path.name}: {str(e)}")

    logger.info(
        f"Compilation complete. Generated {len(compiled_files)} files.")
    return compiled_files


def _get_database_from_content(content: str) -> str:
    """Extract database name from USE statement in content."""
    database = "master"  # Default database
    use_match = re.search(
        r'USE\s+(?:\[([^\]]+)\]|([^\s;]+))\s*;', content, re.IGNORECASE)
    if use_match:
        database = use_match.group(1) if use_match.group(
            1) else use_match.group(2)
    return database


def _execute_sql_statements(content: str, database: str, is_login_file: bool = False) -> bool:
    """Execute SQL statements from content on specified database."""
    try:
        # Build connection string
        db_host = APP_SETTINGS.DB_HOST
        db_port = APP_SETTINGS.DB_PORT
        sa_password = APP_SETTINGS.MSSQL_SA_PASSWORD
        driver = normalize_driver_name(APP_SETTINGS.DB_DRIVER)

        conn_str = build_connection_string(
            "sa", sa_password, database, timeout=30)

        # Connect to database with autocommit
        conn = pyodbc.connect(conn_str, autocommit=True)

        # Try to execute the entire script first
        try:
            cursor = conn.cursor()
            cursor.execute(content)
            return True
        except Exception as script_error:
            # If executing the full script fails and it's a login file, try statement-by-statement
            if is_login_file:
                logger.debug(
                    f"Executing login file statement-by-statement after script error: {str(script_error)}")

                # Extract statements
                statements = []
                current_statement = []

                # First remove comments and empty lines
                cleaned_lines = []
                for line in content.splitlines():
                    stripped = line.strip()
                    if stripped and not stripped.startswith('--'):
                        cleaned_lines.append(line)

                # Group statements between GO commands
                for line in cleaned_lines:
                    if line.strip().upper() == "GO":
                        if current_statement:
                            statements.append('\n'.join(current_statement))
                            current_statement = []
                    else:
                        current_statement.append(line)

                # Add any remaining statements
                if current_statement:
                    statements.append('\n'.join(current_statement))

                # Execute each statement
                cursor = conn.cursor()
                for stmt in statements:
                    if not stmt.strip():
                        continue

                    try:
                        cursor.execute(stmt)
                    except Exception as e:
                        error_str = str(e)

                        # Filter warnings we can safely ignore for login files
                        if "Cannot drop the login" in error_str or "Could not load the DLL" in error_str:
                            pass
                        else:
                            logger.warning(
                                f"Non-critical login error: {error_str}")

                conn.close()
                return True
            else:
                # For non-login files, split by GO and execute each batch
                statements = []
                current_statement = []

                for line in content.splitlines():
                    stripped = line.strip()
                    if not stripped or stripped.startswith('--'):
                        continue

                    if stripped.upper() == "GO":
                        if current_statement:
                            statements.append('\n'.join(current_statement))
                            current_statement = []
                    else:
                        current_statement.append(line)

                if current_statement:
                    statements.append('\n'.join(current_statement))

                # Execute each statement
                cursor = conn.cursor()
                for stmt in statements:
                    if not stmt.strip():
                        continue

                    try:
                        cursor.execute(stmt)
                    except Exception as e:
                        error_str = str(e)
                        if "cannot find the object" in error_str.lower():
                            logger.warning(
                                f"Object not found warning: {error_str}")
                        else:
                            logger.error(
                                f"Error executing statement: {error_str}")
                            conn.close()
                            return False

                conn.close()
                return True

    except Exception as e:
        logger.error(f"Error executing SQL: {str(e)}")
        return False


def _execute_login_file(file_path: Path) -> bool:
    """Execute a login SQL file."""
    try:
        # Read the file content
        content = file_path.read_text(encoding='utf-8')
        database = _get_database_from_content(content)

        logger.info(
            f"Executing login file {file_path.name} on database: {database}")
        return _execute_sql_statements(content, database, is_login_file=True)

    except Exception as e:
        logger.error(f"Error executing login file {file_path.name}: {str(e)}")
        # Don't fail the process for login errors
        return True


def _execute_sql_file(file_path: Path) -> bool:
    """Execute a single compiled SQL file."""
    # Use special handling for login files
    if "create-login" in file_path.name.lower():
        return _execute_login_file(file_path)

    try:
        content = file_path.read_text(encoding='utf-8')
        database = _get_database_from_content(content)

        logger.info(f"Executing {file_path.name} on database: {database}")
        success = _execute_sql_statements(content, database)

        if success:
            logger.info(f"Successfully executed: {file_path.name}")
            return True
        else:
            logger.error(f"Failed to execute {file_path.name}")
            return False

    except Exception as e:
        logger.error(f"Error executing {file_path.name}: {str(e)}")

        # Don't fail completely on security file errors
        if "create-user" in file_path.name.lower():
            logger.warning(f"Non-critical security file error: {str(e)}")
            return True

        return False


def reset_database() -> bool:
    """
    Reset the database by compiling all SQL scripts and executing them
    in the correct order.

    Returns:
        bool: True if successful, False otherwise
    """
    try:
        logger.info("Starting database reset...")

        # Compile SQL files
        compiled_files = compile_sql_files()

        if not compiled_files:
            logger.error("No SQL files were compiled")
            return False

        # Sort compiled files by filename (which contains the execution order)
        compiled_files.sort(key=lambda x: x.name)

        # Execute each file in order
        for file_path in compiled_files:
            success = _execute_sql_file(file_path)
            if not success and not any(x in file_path.name.lower() for x in ["backup", "04-backup"]):
                logger.error(
                    f"Failed to execute {file_path.name}, stopping reset process")
                return False

        logger.info("Database reset completed successfully")
        return True

    except Exception as e:
        logger.error(f"Database reset failed: {str(e)}")
        return False
