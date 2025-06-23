"""Repository logic for authentication related database operations."""

from __future__ import annotations

import logging
from typing import Dict, Optional

import pyodbc

from app.core.config import APP_SETTINGS
from app.db.connection import (
    get_connection_with_credentials,
)

logger = logging.getLogger("app.db.repositories.auth")


class AuthRepository:
    """Handle interactions with authentication stored procedures."""

    def _call_sp_get_info_login(
        self, connection: pyodbc.Connection, login_name: str
    ) -> Optional[Dict[str, str]]:
        """Call dbo.sp_Get_Info_Login and return user info dict or None."""
        cursor = connection.cursor()
        try:
            cursor.execute("EXEC dbo.sp_Get_Info_Login ?", login_name)
            row = cursor.fetchone()
            if not row:
                return None
            return {
                "username": row.USERNAME if hasattr(row, "USERNAME") else row[0],
                "fullname": row.HOTEN if hasattr(row, "HOTEN") else row[1],
                "role": row.TENNHOM if hasattr(row, "TENNHOM") else row[2],
            }
        finally:
            cursor.close()

    def _call_sp_check_login_sv(
        self, connection: pyodbc.Connection, masv: str, password: str
    ) -> Optional[Dict[str, str]]:
        cursor = connection.cursor()
        try:
            cursor.execute("EXEC dbo.sp_Check_Login_SV ?, ?", masv, password)
            row = cursor.fetchone()
            if not row:
                return None
            return {
                "username": row.USERNAME if hasattr(row, "USERNAME") else row[0],
                "fullname": row.HOTEN if hasattr(row, "HOTEN") else row[1],
                "role": row.TENNHOM if hasattr(row, "TENNHOM") else row[2],
            }
        finally:
            cursor.close()

    # Public methods -----------------------------------------------------

    def login_teacher(self, login_name: str, password: str) -> Dict[str, str]:
        """Attempt PGV/KHOA login using provided SQL credentials."""
        conn = get_connection_with_credentials(login_name, password)
        try:
            user_info = self._call_sp_get_info_login(conn, login_name)
            if user_info is None:
                raise ValueError(
                    "Failed to retrieve user info for teacher login")
            user_info["username"] = login_name
            user_info["password"] = password
            return user_info
        finally:
            conn.close()

    def login_student(self, masv: str, password: str) -> Dict[str, str]:
        """Attempt student login via shared SV credentials."""
        sv_user = APP_SETTINGS.MSSQL_SV_USER
        sv_pwd = APP_SETTINGS.MSSQL_SV_PASSWORD
        conn = get_connection_with_credentials(sv_user, sv_pwd)
        try:
            user_info = self._call_sp_check_login_sv(conn, masv, password)
            if user_info is None:
                raise ValueError("Sai mã sinh viên hoặc mật khẩu")
            user_info["username"] = masv
            user_info["password"] = password
            return user_info
        finally:
            conn.close()
