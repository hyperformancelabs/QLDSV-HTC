"""Service layer for lecturer management."""

from __future__ import annotations

import logging
from typing import List, Dict, Any, Optional

from fastapi import HTTPException, status

from app.db.connection import get_connection_with_credentials
from app.db.repositories.giangvien import GiangVienRepository
from app.schemas.giangvien import (
    CreateGiangVienRequest, UpdateGiangVienRequest,
    CreateLoginRequest, UpdatePasswordRequest, ToggleLoginRequest
)

logger = logging.getLogger(__name__)


class GiangVienService:
    """Service for managing GiangVien data and accounts."""

    def __init__(self) -> None:
        """Initialize service with repository."""
        self.repository = GiangVienRepository()

    def _get_connection(self, user: Dict[str, Any]):
        """Get a database connection using user credentials."""
        return get_connection_with_credentials(user["username"], user["password"])

    def _handle_db_exception(self, e: Exception):
        """Handle database exceptions and raise appropriate HTTP exceptions."""
        error_msg = str(e)
        logger.error(f"Service layer error: {error_msg}")

        if "does not exist" in error_msg or "không tồn tại" in error_msg:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail=error_msg)
        if "already exists" in error_msg or "đã tồn tại" in error_msg or "đã có tài khoản" in error_msg:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT, detail=error_msg)
        if "permission" in error_msg:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, detail=error_msg)

        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=error_msg)

    def get_all(
        self,
        user: Dict[str, Any],
        search: Optional[str],
        makhoa: Optional[str],
        hocvi: Optional[str],
        has_login: Optional[bool],
    ) -> List[Dict[str, Any]]:
        """Get all lecturers, applying filters based on user role."""
        try:
            # KHOA users can only see their own department
            if user["role"] == "KHOA":
                makhoa = user.get("makhoa")

            with self._get_connection(user) as conn:
                return self.repository.get_all(conn, search, makhoa, hocvi, has_login)
        except Exception as e:
            self._handle_db_exception(e)

    def get_by_id(self, user: Dict[str, Any], magv: str) -> Optional[Dict[str, Any]]:
        try:
            with self._get_connection(user) as conn:
                lecturer = self.repository.get_by_id(conn, magv)
                if not lecturer:
                    raise HTTPException(
                        status_code=status.HTTP_404_NOT_FOUND, detail="Lecturer not found")
                return lecturer
        except Exception as e:
            self._handle_db_exception(e)

    def create(self, user: Dict[str, Any], lecturer: CreateGiangVienRequest) -> Dict[str, Any]:
        try:
            with self._get_connection(user) as conn:
                return self.repository.create(conn, lecturer)
        except Exception as e:
            self._handle_db_exception(e)

    def update(self, user: Dict[str, Any], magv: str, lecturer: UpdateGiangVienRequest) -> Dict[str, Any]:
        try:
            with self._get_connection(user) as conn:
                return self.repository.update(conn, magv, lecturer)
        except Exception as e:
            self._handle_db_exception(e)

    def delete(self, user: Dict[str, Any], magv: str) -> None:
        try:
            with self._get_connection(user) as conn:
                self.repository.delete(conn, magv)
        except Exception as e:
            self._handle_db_exception(e)

    def create_login(self, user: Dict[str, Any], magv: str, req: CreateLoginRequest) -> Dict[str, Any]:
        try:
            with self._get_connection(user) as conn:
                return self.repository.create_login(conn, magv, req.loginname, req.password, req.role)
        except Exception as e:
            self._handle_db_exception(e)

    def delete_login(self, user: Dict[str, Any], magv: str) -> None:
        try:
            with self._get_connection(user) as conn:
                self.repository.delete_login(conn, magv)
        except Exception as e:
            self._handle_db_exception(e)

    def update_password(self, user: Dict[str, Any], magv: str, req: UpdatePasswordRequest) -> Dict[str, Any]:
        try:
            with self._get_connection(user) as conn:
                return self.repository.update_password(conn, magv, req.new_password)
        except Exception as e:
            self._handle_db_exception(e)

    def toggle_login(self, user: Dict[str, Any], magv: str, req: ToggleLoginRequest) -> Dict[str, Any]:
        try:
            with self._get_connection(user) as conn:
                return self.repository.toggle_login(conn, magv, req.is_disabled)
        except Exception as e:
            self._handle_db_exception(e)
