"""Repository for lecturer data and account management."""

from __future__ import annotations

import logging
from typing import List, Dict, Any, Optional

import pyodbc

from app.db.connection import get_connection_with_credentials
from app.schemas.giangvien import CreateGiangVienRequest, UpdateGiangVienRequest

logger = logging.getLogger(__name__)


class GiangVienRepository:
    """Repository for managing GiangVien data and accounts."""

    def _execute_sp(
        self, connection: pyodbc.Connection, sp_name: str, *params
    ) -> List[Dict[str, Any]]:
        """Execute a stored procedure and return the results as a list of dictionaries."""
        try:
            # Correctly format the placeholder string for pyodbc
            placeholders = ", ".join("?" for _ in params)
            sql = f"EXEC {sp_name} {placeholders}"

            cursor = connection.cursor()
            cursor.execute(sql, params)

            if cursor.description:
                columns = [column[0] for column in cursor.description]
                results = [dict(zip(columns, row))
                           for row in cursor.fetchall()]
            else:
                results = []

            # Stored procedures might not automatically commit in all setups
            if not connection.autocommit:
                connection.commit()

            cursor.close()
            return results
        except pyodbc.Error as e:
            connection.rollback()
            # Re-raise the exception with a more descriptive message
            sqlstate = e.args[0]
            if sqlstate == '23000':  # Integrity constraint violation
                raise Exception(f"Database integrity error: {e.args[1]}")
            elif sqlstate == '42000':  # Syntax error or access violation
                raise Exception(
                    f"Database permission or syntax error: {e.args[1]}")
            logger.error(f"Error executing stored procedure {sp_name}: {e}")
            raise Exception(f"A database error occurred: {e.args[1]}")

    def get_all(
        self,
        connection: pyodbc.Connection,
        search: Optional[str],
        makhoa: Optional[str],
        hocvi: Optional[str],
        has_login: Optional[bool],
    ) -> List[Dict[str, Any]]:
        """Get all lecturers with filters."""
        has_login_bit = None
        if has_login is not None:
            has_login_bit = 1 if has_login else 0

        return self._execute_sp(
            connection,
            "dbo.sp_Search_GiangVien_Advanced",
            search,
            makhoa,
            hocvi,
            has_login_bit,
        )

    def get_by_id(self, connection: pyodbc.Connection, magv: str) -> Optional[Dict[str, Any]]:
        """Get a single lecturer by their ID."""
        results = self._execute_sp(
            connection, "dbo.sp_Search_GiangVien_Advanced", magv, None, None, None)
        return results[0] if results else None

    def create(self, connection: pyodbc.Connection, lecturer: CreateGiangVienRequest) -> Dict[str, Any]:
        """Create a new lecturer."""
        self._execute_sp(
            connection,
            "dbo.sp_GiangVien_Create",
            lecturer.magv,
            lecturer.ho,
            lecturer.ten,
            lecturer.makhoa,
            lecturer.hocvi,
            lecturer.hocham,
            lecturer.chuyenmon,
        )
        return self.get_by_id(connection, lecturer.magv)

    def update(self, connection: pyodbc.Connection, magv: str, lecturer: UpdateGiangVienRequest) -> Dict[str, Any]:
        """Update an existing lecturer."""
        self._execute_sp(
            connection,
            "dbo.sp_GiangVien_Update",
            magv,
            lecturer.ho,
            lecturer.ten,
            lecturer.makhoa,
            lecturer.hocvi,
            lecturer.hocham,
            lecturer.chuyenmon,
        )
        return self.get_by_id(connection, magv)

    def delete(self, connection: pyodbc.Connection, magv: str) -> None:
        """Delete a lecturer."""
        self._execute_sp(connection, "dbo.sp_GiangVien_Delete", magv)

    def create_login(self, connection: pyodbc.Connection, magv: str, loginname: str, password: str, role: str) -> Dict[str, Any]:
        """Create a login for a lecturer."""
        result = self._execute_sp(
            connection, "dbo.sp_Create_GiangVien_Login", loginname, password, magv, role
        )
        return result[0]

    def delete_login(self, connection: pyodbc.Connection, magv: str) -> None:
        """Delete a lecturer's login."""
        self._execute_sp(connection, "dbo.sp_Delete_GiangVien_Login", magv)

    def update_password(self, connection: pyodbc.Connection, magv: str, new_password: str) -> Dict[str, Any]:
        """Update a lecturer's password."""
        result = self._execute_sp(
            connection, "dbo.sp_Update_GiangVien_Password", magv, new_password)
        return result[0]

    def toggle_login(self, connection: pyodbc.Connection, magv: str, is_disabled: bool) -> Dict[str, Any]:
        """Disable or enable a lecturer's login."""
        result = self._execute_sp(
            connection, "dbo.sp_Toggle_GiangVien_Login", magv, 1 if is_disabled else 0)
        return result[0]
