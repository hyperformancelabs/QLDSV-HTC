"""Repository functions for MONHOC (subject) entity."""

from __future__ import annotations

import logging
from typing import List, Dict, Optional

import pyodbc

from app.db.connection import get_connection_with_credentials
from app.core.config import APP_SETTINGS

logger = logging.getLogger("app.db.repositories.monhoc")


class MonHocRepository:
    """Handle database operations for MONHOC entity through stored procedures."""

    def __init__(self, user: Dict[str, str]):
        """
        Initialize the repository with a database connection.

        Args:
            user: The authenticated user dictionary from the session.
                  It must contain 'username' and 'password' keys.
        """
        username = user.get("username")
        password = user.get("password")

        # Fallback to PGV user if no specific user credentials are provided
        # This is crucial for operations initiated by PGV/KHOA roles
        if not username or not password:
            raise ValueError(
                "User credentials (username, password) not found in session. Cannot connect to the database.")

        self.conn = get_connection_with_credentials(
            user=username, password=password)

    def _row_to_dict(self, row: pyodbc.Row) -> Dict[str, str | int | bool]:
        """
        Transform pyodbc row to a dictionary with consistent keys.

        Args:
            row: Database row from pyodbc

        Returns:
            Dictionary with standardized keys
        """
        # Handle both attribute access and index access (depending on cursor settings)
        return {
            "MAMH": row.MAMH if hasattr(row, "MAMH") else row[0],
            "TENMH": row.TENMH if hasattr(row, "TENMH") else row[1],
            "SOTIET_LT": row.SOTIET_LT if hasattr(row, "SOTIET_LT") else row[2],
            "SOTIET_TH": row.SOTIET_TH if hasattr(row, "SOTIET_TH") else row[3],
            "IS_LINKED": row.IS_LINKED if hasattr(row, "IS_LINKED") else row[4] if len(row) > 4 else False,
        }

    def list(self, mamh: Optional[str] = None, tenmh: Optional[str] = None) -> List[Dict]:
        """
        Fetch list of subjects with optional filters.

        Args:
            mamh: Optional subject code filter (exact match)
            tenmh: Optional subject name filter (LIKE pattern)

        Returns:
            List of subject dictionaries

        Raises:
            pyodbc.Error: On database errors
        """
        try:
            cursor = self.conn.cursor()

            # Execute stored procedure with parameters
            cursor.execute("EXEC dbo.SP_MonHoc_Select ?, ?", mamh, tenmh)

            # Fetch and transform results
            rows = cursor.fetchall()
            return [self._row_to_dict(row) for row in rows]
        except pyodbc.Error as err:
            logger.error(f"Error fetching subject list: {err}")
            raise
        finally:
            # The connection is managed by the service layer or context
            pass

    def upsert(self, mamh: str, tenmh: str, sotiet_lt: int, sotiet_th: int) -> None:
        """
        Create or update a subject.

        Args:
            mamh: Subject code (primary key)
            tenmh: Subject name
            sotiet_lt: Theory hours
            sotiet_th: Practice hours

        Raises:
            pyodbc.Error: On database errors, including constraint violations
        """
        try:
            cursor = self.conn.cursor()

            # Execute upsert stored procedure
            cursor.execute(
                "EXEC dbo.SP_MonHoc_Upsert ?, ?, ?, ?",
                mamh,
                tenmh,
                sotiet_lt,
                sotiet_th,
            )

            # Commit the transaction
            self.conn.commit()
            logger.info(f"Successfully upserted subject: {mamh}")
        except pyodbc.Error as err:
            self.conn.rollback()
            logger.error(f"Error upserting subject: {err}")
            raise
        finally:
            pass

    def delete(self, mamh: str) -> None:
        """
        Delete a subject by code.

        Args:
            mamh: Subject code to delete

        Raises:
            pyodbc.Error: If deletion fails (e.g., foreign key constraints)
        """
        try:
            cursor = self.conn.cursor()

            # Execute delete stored procedure
            cursor.execute("EXEC dbo.SP_MonHoc_Delete ?", mamh)

            # Commit the transaction
            self.conn.commit()
            logger.info(f"Successfully deleted subject: {mamh}")
        except pyodbc.Error as err:
            self.conn.rollback()
            logger.error(f"Error deleting subject {mamh}: {err}")
            raise
        finally:
            pass

    def close_connection(self):
        """Close the database connection."""
        if self.conn:
            self.conn.close()
