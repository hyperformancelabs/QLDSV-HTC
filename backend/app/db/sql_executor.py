"""
Unified SQL Executor for QLDSV-HTC

This module provides a unified interface for executing SQL queries and files,
abstracting away platform-specific differences and connection methods.
Handles SQL Server-specific commands like GO batch separator.
"""

import os
import subprocess
import pyodbc
import re
from pathlib import Path
from typing import Optional, Union, List, Tuple
from app.core.config import get_settings
from app.core.logger import setup_logger

# Setup logger
logger = setup_logger("sql_executor")

# Get settings
settings = get_settings()


class SQLExecutor:
    """
    Unified SQL executor that handles both query strings and SQL files.

    Automatically chooses the best execution method based on platform and availability:
    - macOS: Prefers Docker exec method for better compatibility
    - Other platforms: Prefers ODBC when available, falls back to Docker exec

    Uses the default database from .env configuration when no database is specified.

    Key Features:
    - Handles SQL Server GO batch separator commands
    - Supports multi-batch SQL execution for ODBC
    - Normalizes SQL content for cross-platform compatibility
    """

    def __init__(self):
        self.settings = settings
        self.logger = logger

    def execute_sql(self, sql_input: Union[str, Path], database: Optional[str] = None, user_type: Optional[str] = None) -> str:
        """
        Execute SQL query or file with automatic method selection.

        Args:
            sql_input: SQL query string or Path to SQL file
            database: Optional database name to connect to. If None, uses default from .env
            user_type: Optional user type ('sa', 'app_user', 'pgv_user', 'khoa_user', 'sv_user'). Defaults to 'sa'

        Returns:
            Query result as string

        Raises:
            Exception: If SQL execution fails
        """
        # Use default database from settings if none specified
        target_database = database or self.settings.DB_NAME

        if isinstance(sql_input, (str, Path)) and Path(sql_input).exists():
            # It's a file path
            return self._execute_sql_file(Path(sql_input), target_database, user_type)
        else:
            # It's a query string
            return self._execute_sql_query(str(sql_input), target_database, user_type)

    def _execute_sql_query(self, sql_query: str, database: Optional[str] = None, user_type: Optional[str] = None) -> str:
        """
        Execute SQL query string using the best available method.

        Args:
            sql_query: SQL query to execute
            database: Optional database name to connect to. If None, uses default from .env
            user_type: Optional user type ('sa', 'app_user', 'pgv_user', 'khoa_user', 'sv_user'). Defaults to 'sa'

        Returns:
            Query result as string
        """
        # Use default database from settings if none specified
        target_database = database or self.settings.DB_NAME

        self.logger.debug(
            f"Executing SQL query in database: {target_database} as user: {user_type or 'sa'}")

        # Normalize SQL content before execution
        normalized_sql = self._normalize_sql(sql_query)

        # On macOS, prefer Docker exec method
        if self.settings.IS_MACOS:
            try:
                return self._execute_via_docker(normalized_sql, target_database, user_type=user_type)
            except Exception as e:
                self.logger.warning(
                    f"Docker exec failed on macOS, trying ODBC fallback: {e}")
                return self._execute_via_odbc(normalized_sql, target_database, user_type=user_type)
        else:
            # On other platforms, try ODBC first, fallback to Docker
            try:
                return self._execute_via_odbc(normalized_sql, target_database, user_type=user_type)
            except Exception as e:
                self.logger.warning(
                    f"ODBC failed, trying Docker exec fallback: {e}")
                return self._execute_via_docker(normalized_sql, target_database, user_type=user_type)

    def _execute_sql_file(self, sql_file: Path, database: Optional[str] = None, user_type: Optional[str] = None) -> str:
        """Execute SQL file using the best available method."""
        if not sql_file.exists():
            raise FileNotFoundError(f"SQL file not found: {sql_file}")

        # Use default database from settings if none specified
        target_database = database or self.settings.DB_NAME

        self.logger.info(
            f"Executing SQL file: {sql_file.name} in database: {target_database} as user: {user_type or 'sa'}")

        # Read the SQL file
        with open(sql_file, 'r', encoding='utf-8') as f:
            sql_content = f.read()

        # Replace environment variables
        sql_content = self._replace_variables(sql_content)

        # Normalize SQL content
        normalized_sql = self._normalize_sql(sql_content)

        # On macOS, prefer Docker exec with file method
        if self.settings.IS_MACOS:
            try:
                return self._execute_file_via_docker(sql_file, normalized_sql, target_database, user_type=user_type)
            except Exception as e:
                self.logger.warning(
                    f"Docker file exec failed on macOS, trying ODBC fallback: {e}")
                return self._execute_via_odbc(normalized_sql, target_database, user_type=user_type)
        else:
            # On other platforms, try ODBC first, fallback to Docker
            try:
                return self._execute_via_odbc(normalized_sql, target_database, user_type=user_type)
            except Exception as e:
                self.logger.warning(
                    f"ODBC failed, trying Docker file exec fallback: {e}")
                return self._execute_file_via_docker(sql_file, normalized_sql, target_database, user_type=user_type)

    def _normalize_sql(self, sql_content: str) -> str:
        """
        Normalize SQL content for cross-platform execution.

        - Removes or handles SQL Server-specific comments
        - Normalizes whitespace and line endings
        - Preserves important formatting

        Args:
            sql_content: Raw SQL content

        Returns:
            Normalized SQL content
        """
        if not sql_content or not sql_content.strip():
            return sql_content

        # Normalize line endings to \n
        normalized = sql_content.replace('\r\n', '\n').replace('\r', '\n')

        # Remove excessive blank lines (more than 2 consecutive)
        normalized = re.sub(r'\n\s*\n\s*\n+', '\n\n', normalized)

        # Remove trailing whitespace from each line
        lines = [line.rstrip() for line in normalized.split('\n')]
        normalized = '\n'.join(lines)

        return normalized.strip()

    def _split_sql_batches(self, sql_content: str) -> List[str]:
        """
        Split SQL content into batches based on GO statements.

        Handles various GO statement formats:
        - GO (standalone)
        - GO 5 (with count)
        - go (case insensitive)
        - Comments before/after GO

        Args:
            sql_content: SQL content that may contain GO statements

        Returns:
            List of SQL batches (without GO statements)
        """
        if not sql_content or not sql_content.strip():
            return []

        # Pattern to match GO statements with optional count and surrounding whitespace/comments
        # This matches:
        # - GO (case insensitive)
        # - GO 5 (with optional count)
        # - -- comment\nGO
        # - GO\n-- comment
        go_pattern = r'^\s*(?:--.*\n)?\s*GO\s*(?:\d+)?\s*(?:--.*)?$'

        # Split by GO statements (case insensitive, multiline mode)
        batches = re.split(go_pattern, sql_content,
                           flags=re.IGNORECASE | re.MULTILINE)

        # Clean up batches - remove empty ones and strip whitespace
        cleaned_batches = []
        for batch in batches:
            cleaned_batch = batch.strip()
            if cleaned_batch:
                cleaned_batches.append(cleaned_batch)

        # If no GO statements found, treat entire content as one batch
        if len(cleaned_batches) <= 1 and sql_content.strip():
            return [sql_content.strip()]

        self.logger.debug(f"Split SQL into {len(cleaned_batches)} batches")
        return cleaned_batches

    def _execute_via_docker(self, sql_query: str, database: Optional[str] = None, timeout: int = 30, user_type: Optional[str] = None) -> str:
        """Execute SQL query using Docker exec method."""
        try:
            # Use default database if none specified
            target_database = database or self.settings.DB_NAME

            # Get user credentials based on user_type
            username, password = self._get_user_credentials(user_type)

            db_param = f"-d {target_database}" if target_database else ""
            container_name = self.settings.DB_CONTAINER_NAME
            escaped_password = password.replace("'", "'\\''")  # Escape quotes

            # Docker exec handles GO statements natively via sqlcmd
            # Escape double quotes in SQL query
            escaped_query = sql_query.replace('"', '\\"')

            cmd = (
                f"docker exec -i {container_name} /opt/mssql-tools18/bin/sqlcmd "
                f"-S localhost -U {username} -P '{escaped_password}' -C {db_param} "
                f"-Q \"{escaped_query}\" -h-1 -s\",\" -W -w 999 -t {timeout}"
            )

            self.logger.debug(
                f"Docker exec command for user {username} targeting database {target_database}")

            result = subprocess.run(
                cmd, shell=True, capture_output=True, text=True)

            if result.returncode != 0:
                error_msg = f"Docker exec SQL execution failed: {result.stderr}"
                self.logger.error(error_msg)
                raise Exception(error_msg)

            self.logger.debug(
                f"Docker exec SQL execution successful for user {username}")
            return result.stdout.strip()

        except Exception as e:
            self.logger.error(f"Error in Docker exec method: {e}")
            raise

    def _execute_file_via_docker(self, sql_file: Path, sql_content: str, database: Optional[str] = None, user_type: Optional[str] = None) -> str:
        """Execute SQL file using Docker exec method with temporary file."""
        try:
            # Use default database if none specified
            target_database = database or self.settings.DB_NAME

            # Get user credentials based on user_type
            username, password = self._get_user_credentials(user_type)

            container_name = self.settings.DB_CONTAINER_NAME
            temp_file = f"/tmp/{sql_file.name}"

            # Docker exec handles GO statements natively via sqlcmd
            # Copy script to container
            copy_cmd = f"docker exec -i {container_name} bash -c 'cat > {temp_file}'"
            copy_result = subprocess.run(
                copy_cmd, shell=True, input=sql_content, text=True, capture_output=True
            )

            if copy_result.returncode != 0:
                raise Exception(
                    f"Failed to copy script to container: {copy_result.stderr}")

            # Execute the script in container
            db_param = f"-d {target_database}" if target_database else ""
            exec_cmd = (
                f"docker exec {container_name} /opt/mssql-tools18/bin/sqlcmd "
                f"-S localhost -U {username} -P '{password}' -C {db_param} -i {temp_file}"
            )

            exec_result = subprocess.run(
                exec_cmd, shell=True, capture_output=True, text=True)

            # Clean up temp file
            cleanup_cmd = f"docker exec {container_name} rm -f {temp_file}"
            subprocess.run(cleanup_cmd, shell=True, capture_output=True)

            if exec_result.returncode != 0:
                raise Exception(
                    f"SQL file execution failed: {exec_result.stderr}")

            self.logger.info(
                f"Successfully executed {sql_file.name} via Docker for user {username}")
            return exec_result.stdout.strip()

        except Exception as e:
            self.logger.error(f"Error in Docker file exec method: {e}")
            raise

    def _execute_via_odbc(self, sql_content: str, database: Optional[str] = None, user_type: Optional[str] = None) -> str:
        """
        Execute SQL content using ODBC connection with GO batch handling.

        Splits SQL content by GO statements and executes each batch separately.
        This is necessary because pyodbc doesn't understand GO batch separators.
        """
        try:
            # Use default database if none specified
            target_database = database or self.settings.DB_NAME

            # Get user credentials based on user_type
            username, password = self._get_user_credentials(user_type)

            # Build connection string with appropriate credentials
            conn_str = (
                f"DRIVER={{ODBC Driver 18 for SQL Server}};"
                f"SERVER={self.settings.DB_HOST},{self.settings.DB_PORT};"
                f"DATABASE={target_database};"
                f"UID={username};"
                f"PWD={password};"
                f"TrustServerCertificate=yes;"
                f"Connection Timeout=30;"
                f"Encrypt=yes;"
            )

            self.logger.debug(
                f"Connecting via ODBC to database: {target_database} as user: {username}")
            self.logger.debug(
                f"Connection string (without password): DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={self.settings.DB_HOST},{self.settings.DB_PORT};DATABASE={target_database};UID={username};TrustServerCertificate=yes;Connection Timeout=30;Encrypt=yes;")

            # Split SQL into batches by GO statements
            sql_batches = self._split_sql_batches(sql_content)

            if not sql_batches:
                self.logger.warning("No SQL batches found to execute")
                return "No SQL statements to execute"

            try:
                conn = pyodbc.connect(conn_str)
                self.logger.debug(
                    f"ODBC connection established successfully for {username}")
            except pyodbc.Error as conn_error:
                self.logger.error(
                    f"Failed to establish ODBC connection: {conn_error}")
                if "timeout" in str(conn_error).lower():
                    self.logger.error(
                        f"Connection timeout detected. Verify SQL Server is running and accessible at {self.settings.DB_HOST}:{self.settings.DB_PORT}")
                elif "password" in str(conn_error).lower() or "login" in str(conn_error).lower():
                    self.logger.error(
                        f"Authentication failed for user {username}. Verify credentials.")
                raise Exception(f"ODBC connection failed: {str(conn_error)}")

            cursor = conn.cursor()

            all_results = []
            total_rows_affected = 0

            try:
                # Execute each batch separately
                for i, batch in enumerate(sql_batches, 1):
                    batch = batch.strip()
                    if not batch:
                        continue

                    self.logger.debug(
                        f"Executing batch {i}/{len(sql_batches)}")
                    self.logger.debug(
                        f"Batch content (first 200 chars): {batch[:200]}...")

                    try:
                        cursor.execute(batch)

                        # Handle results based on statement type
                        if self._is_select_statement(batch):
                            rows = cursor.fetchall()
                            if rows:
                                # Convert to string format similar to sqlcmd output
                                batch_result = '\n'.join(
                                    [','.join([str(col) if col is not None else 'NULL' for col in row]) for row in rows])
                                all_results.append(
                                    f"Batch {i} results:\n{batch_result}")
                            else:
                                all_results.append(
                                    f"Batch {i}: No results returned")
                        else:
                            # For non-SELECT queries, get row count
                            rows_affected = cursor.rowcount
                            total_rows_affected += rows_affected if rows_affected > 0 else 0
                            all_results.append(
                                f"Batch {i}: Command completed successfully. Rows affected: {rows_affected}")

                        # Commit after each batch to ensure changes are persisted
                        conn.commit()

                    except pyodbc.Error as batch_error:
                        # Log the error but continue with next batch if possible
                        error_msg = f"Error in batch {i}: {str(batch_error)}"
                        self.logger.error(error_msg)
                        all_results.append(error_msg)

                        # For critical errors, re-raise
                        if "syntax error" in str(batch_error).lower() or "invalid" in str(batch_error).lower():
                            raise Exception(
                                f"Critical error in batch {i}: {str(batch_error)}")

                        # For non-critical errors, continue
                        continue

                # Prepare final result
                if all_results:
                    final_result = '\n\n'.join(all_results)
                else:
                    final_result = f"All {len(sql_batches)} batches completed successfully. Total rows affected: {total_rows_affected}"

            finally:
                cursor.close()
                conn.close()

            self.logger.debug("ODBC SQL execution successful")
            return final_result

        except pyodbc.Error as e:
            self.logger.error(f"ODBC error: {e}")
            raise Exception(f"ODBC execution error: {str(e)}")
        except Exception as e:
            self.logger.error(f"Error in ODBC method: {e}")
            raise

    def _is_select_statement(self, sql_statement: str) -> bool:
        """
        Check if a SQL statement is a SELECT statement.

        Args:
            sql_statement: SQL statement to check

        Returns:
            True if it's a SELECT statement, False otherwise
        """
        # Remove comments and normalize whitespace
        cleaned_sql = re.sub(r'--.*$', '', sql_statement, flags=re.MULTILINE)
        cleaned_sql = re.sub(r'/\*.*?\*/', '', cleaned_sql, flags=re.DOTALL)
        cleaned_sql = cleaned_sql.strip()

        # Check if it starts with SELECT (case insensitive)
        return cleaned_sql.upper().startswith('SELECT')

    def _replace_variables(self, sql_content: str) -> str:
        """Replace environment variables in SQL content."""
        replacements = {
            '$(DB_NAME)': self.settings.DB_NAME,
            '$(MSSQL_APP_USER)': self.settings.MSSQL_APP_USER,
            '$(MSSQL_APP_PASSWORD)': self.settings.MSSQL_APP_PASSWORD,
            '$(MSSQL_PGV_USER)': self.settings.MSSQL_PGV_USER,
            '$(MSSQL_PGV_PASSWORD)': self.settings.MSSQL_PGV_PASSWORD,
            '$(MSSQL_KHOA_USER)': self.settings.MSSQL_KHOA_USER,
            '$(MSSQL_KHOA_PASSWORD)': self.settings.MSSQL_KHOA_PASSWORD,
            '$(MSSQL_SV_USER)': self.settings.MSSQL_SV_USER,
            '$(MSSQL_SV_PASSWORD)': self.settings.MSSQL_SV_PASSWORD,
        }

        for placeholder, value in replacements.items():
            sql_content = sql_content.replace(placeholder, value)

        return sql_content

    def detect_target_database(self, sql_content: str) -> str:
        """
        Detect target database from USE statement in SQL content.

        Looks for patterns like:
        - USE [$(DB_NAME)];
        - USE [master];
        - USE $(DB_NAME);
        - USE master;

        Args:
            sql_content: SQL content to analyze

        Returns:
            Target database name ('master' or the configured database name)
            If no USE statement found, returns the default database from settings
        """
        if not sql_content or not sql_content.strip():
            return self.settings.DB_NAME

        # Clean the content for analysis (remove comments, normalize whitespace)
        cleaned_content = self._clean_sql_for_analysis(sql_content)

        # Look for USE statements at the beginning of the file
        # Pattern matches: USE [database_name]; or USE database_name;
        use_pattern = r'^\s*USE\s+\[?([^\];\s]+)\]?\s*;'

        match = re.search(use_pattern, cleaned_content,
                          re.IGNORECASE | re.MULTILINE)

        if match:
            db_reference = match.group(1)

            # Handle variable substitution
            if db_reference == '$(DB_NAME)':
                target_db = self.settings.DB_NAME
                self.logger.debug(
                    f"Found USE [$(DB_NAME)] - resolved to: {target_db}")
                return target_db
            elif db_reference.lower() == 'master':
                self.logger.debug(
                    "Found USE [master] - targeting master database")
                return 'master'
            else:
                # Direct database name
                self.logger.debug(
                    f"Found USE [{db_reference}] - targeting: {db_reference}")
                return db_reference

        # No USE statement found, return default
        self.logger.debug(
            f"No USE statement found - using default database: {self.settings.DB_NAME}")
        return self.settings.DB_NAME

    def _clean_sql_for_analysis(self, sql_content: str) -> str:
        """
        Clean SQL content for analysis by removing comments and normalizing whitespace.

        Args:
            sql_content: Raw SQL content

        Returns:
            Cleaned SQL content suitable for pattern matching
        """
        if not sql_content:
            return ""

        # Remove single-line comments (-- style)
        cleaned = re.sub(r'--.*$', '', sql_content, flags=re.MULTILINE)

        # Remove multi-line comments (/* */ style)
        cleaned = re.sub(r'/\*.*?\*/', '', cleaned, flags=re.DOTALL)

        # Normalize whitespace
        cleaned = re.sub(r'\s+', ' ', cleaned)

        return cleaned.strip()

    def _get_user_credentials(self, user_type: Optional[str] = None) -> tuple:
        """
        Get the appropriate username and password based on user_type.
        If user_type is custom (not predefined), attempt to read env var MSSQL_<USERNAME>_PASSWORD.
        """
        if user_type is None or user_type == 'sa':
            return 'sa', self.settings.MSSQL_SA_PASSWORD
        elif user_type == 'app_user':
            return self.settings.MSSQL_APP_USER, self.settings.MSSQL_APP_PASSWORD
        elif user_type == 'pgv_user':
            return self.settings.MSSQL_PGV_USER, self.settings.MSSQL_PGV_PASSWORD
        elif user_type == 'khoa_user':
            return self.settings.MSSQL_KHOA_USER, self.settings.MSSQL_KHOA_PASSWORD
        elif user_type == 'sv_user':
            return self.settings.MSSQL_SV_USER, self.settings.MSSQL_SV_PASSWORD
        else:
            # Assume user_type is the actual username
            dynamic_password = self.settings.get_dynamic_password(user_type)
            if dynamic_password:
                return user_type, dynamic_password
            self.logger.error(
                f"No credentials found for dynamic user '{user_type}'. Ensure environment variable MSSQL_{user_type.upper()}_PASSWORD is set.")
            raise ValueError(f"Missing credentials for user: {user_type}")


# Global executor instance
_executor = None


def get_sql_executor() -> SQLExecutor:
    """Get the global SQL executor instance."""
    global _executor
    if _executor is None:
        _executor = SQLExecutor()
    return _executor


# Convenience functions for backward compatibility and ease of use
def execute_sql(sql_input: Union[str, Path], database: Optional[str] = None, user_type: Optional[str] = None) -> str:
    """
    Execute SQL query or file.

    Args:
        sql_input: SQL query string or Path to SQL file
        database: Optional database name to connect to. If None, uses default from .env (QLDSV_HTC)
        user_type: Optional user type ('sa', 'app_user', 'pgv_user', 'khoa_user', 'sv_user'). Defaults to 'sa'

    Returns:
        Query result as string
    """
    return get_sql_executor().execute_sql(sql_input, database, user_type)


def execute_sql_query(sql_query: str, database: Optional[str] = None, user_type: Optional[str] = None) -> str:
    """
    Execute SQL query string.

    Args:
        sql_query: SQL query to execute
        database: Optional database name to connect to. If None, uses default from .env (QLDSV_HTC)
        user_type: Optional user type ('sa', 'app_user', 'pgv_user', 'khoa_user', 'sv_user'). Defaults to 'sa'

    Returns:
        Query result as string
    """
    return get_sql_executor()._execute_sql_query(sql_query, database, user_type)


def execute_sql_file(sql_file: Union[str, Path], database: Optional[str] = None, user_type: Optional[str] = None) -> str:
    """
    Execute SQL file.

    Args:
        sql_file: Path to SQL file
        database: Optional database name to connect to. If None, uses default from .env (QLDSV_HTC)
        user_type: Optional user type ('sa', 'app_user', 'pgv_user', 'khoa_user', 'sv_user'). Defaults to 'sa'

    Returns:
        Query result as string
    """
    return get_sql_executor()._execute_sql_file(Path(sql_file), database, user_type)


def detect_target_database_from_sql(sql_content: str) -> str:
    """
    Detect target database from USE statement in SQL content.

    Args:
        sql_content: SQL content to analyze

    Returns:
        Target database name ('master' or configured database name)
    """
    return get_sql_executor().detect_target_database(sql_content)
