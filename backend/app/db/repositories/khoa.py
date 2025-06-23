"""Repository functions for KHOA (faculty) entity."""

from __future__ import annotations

import logging
from typing import List, Dict

import pyodbc

from app.db.connection import get_connection_with_credentials

logger = logging.getLogger("app.db.repositories.khoa")


class KhoaRepository:  # noqa: WPS110 – repository pattern
    """Handle database operations for KHOA entity."""

    def __init__(self, user: Dict[str, str]):
        """Initialize the repository with a database connection.

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

    # Internal helpers -----------------------------------------------------
    def _row_to_dict(self, row: pyodbc.Row) -> Dict[str, str]:
        """Transform pyodbc row to a dictionary.

        Args:
            row: Database row

        Returns:
            Dictionary with keys MAKHOA & TENKHOA
        """
        return {
            "MAKHOA": row.MAKHOA if hasattr(row, "MAKHOA") else row[0],
            "TENKHOA": row.TENKHOA if hasattr(row, "TENKHOA") else row[1],
        }

    # Public APIs ----------------------------------------------------------
    def list(self) -> List[Dict[str, str]]:
        """Return list of faculties.

        Returns:
            List of dictionaries with MAKHOA & TENKHOA
        """
        try:
            cursor = self.conn.cursor()
            # Prefer stored procedure if exists else fallback to raw select
            try:
                cursor.execute("EXEC dbo.SP_KHOA_Select")
            except pyodbc.ProgrammingError:
                # SP not found – fallback
                cursor.execute(
                    "SELECT MAKHOA, TENKHOA FROM dbo.KHOA ORDER BY TENKHOA")

            rows = cursor.fetchall()
            return [self._row_to_dict(row) for row in rows]
        except pyodbc.Error as err:
            logger.error(f"Error fetching faculty list: {err}")
            raise

    def close_connection(self) -> None:  # noqa: D401 – imperative mood
        """Close DB connection."""
        if self.conn:
            self.conn.close()
