"""Repository functions for LOP (class) entity."""

from __future__ import annotations

import logging
from typing import List, Dict, Optional

import pyodbc

from app.db.connection import get_connection_with_credentials

logger = logging.getLogger("app.db.repositories.lop")


class LopRepository:
    """Handle database operations for LOP entity through stored procedures."""

    def __init__(self, user: Dict[str, str]):
        """
        Initialize the repository with a database connection.

        Args:
            user: The authenticated user dictionary from the session.
                  It must contain 'username' and 'password' keys.
        """
        username = user.get("username")
        password = user.get("password")

        if not username or not password:
            raise ValueError(
                "User credentials (username, password) not found in session. Cannot connect to the database.")

        self.conn = get_connection_with_credentials(
            user=username, password=password)

    def _row_to_dict(self, row: pyodbc.Row) -> Dict[str, str | int]:
        """
        Transform pyodbc row to a dictionary with consistent keys.

        Args:
            row: Database row from pyodbc

        Returns:
            Dictionary with standardized keys
        """
        result = {}

        # Map column names to values
        column_names = [column[0] for column in row.cursor_description]
        for i, value in enumerate(row):
            column_name = column_names[i]
            result[column_name] = value

        return result

    def list_by_khoa(self, makhoa: Optional[str] = None, khoahoc: Optional[str] = None) -> List[Dict]:
        """
        Fetch list of classes by khoa and optionally khoahoc.

        Args:
            makhoa: Optional khoa code filter
            khoahoc: Optional academic year filter (e.g., "2021-2025")

        Returns:
            List of class dictionaries with student count information

        Raises:
            pyodbc.Error: On database errors
        """
        try:
            cursor = self.conn.cursor()

            # Execute stored procedure with parameters
            cursor.execute(
                "EXEC dbo.SP_LOP_SelectByKhoa ?, ?",
                makhoa if makhoa else None,
                khoahoc if khoahoc else None
            )

            # Fetch and transform results
            rows = cursor.fetchall()
            return [self._row_to_dict(row) for row in rows]
        except pyodbc.Error as err:
            logger.error(f"Error fetching class list: {err}")
            raise
        finally:
            # The connection is managed by the service layer or context
            pass

    def has_students(self, malop: str) -> int:
        """
        Check if a class has associated students.

        Args:
            malop: Class code

        Returns:
            Number of students in the class

        Raises:
            pyodbc.Error: On database errors
        """
        try:
            cursor = self.conn.cursor()

            # Execute stored procedure with parameters
            cursor.execute("EXEC dbo.SP_LOP_HasStudents ?", malop)

            # Fetch result
            result = cursor.fetchone()
            return result[0] if result else 0
        except pyodbc.Error as err:
            logger.error(f"Error checking if class has students: {err}")
            raise
        finally:
            pass

    def upsert(self, malop: str, tenlop: str, khoahoc: str, makhoa: str) -> None:
        """
        Create or update a class.

        Args:
            malop: Class code (primary key)
            tenlop: Class name
            khoahoc: Academic years (e.g., "2021-2025")
            makhoa: Khoa code (foreign key)

        Raises:
            pyodbc.Error: On database errors, including constraint violations
        """
        try:
            cursor = self.conn.cursor()

            # Execute upsert stored procedure
            cursor.execute(
                "EXEC dbo.SP_LOP_Upsert ?, ?, ?, ?",
                malop,
                tenlop,
                khoahoc,
                makhoa,
            )

            # Commit the transaction
            self.conn.commit()
            logger.info(f"Successfully upserted class: {malop}")
        except pyodbc.Error as err:
            self.conn.rollback()
            logger.error(f"Error upserting class: {err}")
            raise
        finally:
            pass

    def delete(self, malop: str) -> None:
        """
        Delete a class by code.

        Args:
            malop: Class code to delete

        Raises:
            pyodbc.Error: If deletion fails (e.g., foreign key constraints)
        """
        try:
            cursor = self.conn.cursor()

            # Execute delete stored procedure
            cursor.execute("EXEC dbo.SP_LOP_Delete ?", malop)

            # Commit the transaction
            self.conn.commit()
            logger.info(f"Successfully deleted class: {malop}")
        except pyodbc.Error as err:
            self.conn.rollback()
            logger.error(f"Error deleting class {malop}: {err}")
            raise
        finally:
            pass

    def close_connection(self):
        """Close the database connection."""
        if self.conn:
            self.conn.close()
