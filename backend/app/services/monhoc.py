"""Business logic for MONHOC (subject) operations."""

from __future__ import annotations

import logging
from typing import List, Dict, Optional

from fastapi import HTTPException, status
import pyodbc

from app.db.repositories.monhoc import MonHocRepository

logger = logging.getLogger("app.services.monhoc")

# Constants for role-based access control
REQUIRED_ROLE = "pgv_role"  # Only PGV can modify
ALLOWED_ROLES = ["pgv_role", "khoa_role"]  # PGV and KHOA can view


class MonHocService:
    """Service layer for MONHOC (subject) operations."""

    def __init__(self) -> None:
        """Initialize the service, repository is no longer a singleton."""
        pass

    # Helper methods
    def _ensure_pgv(self, current_user: Dict[str, str]) -> None:
        """
        Ensure the current user has PGV role.

        Args:
            current_user: The authenticated user dictionary

        Raises:
            HTTPException: If user doesn't have required role
        """
        if not current_user or current_user.get("role") != REQUIRED_ROLE:
            logger.warning(
                f"User with role {current_user.get('role', 'none')} attempted a PGV-only operation")
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Bạn không có quyền thực hiện thao tác này",
            )

    def _validate_monhoc(self, mamh: str, tenmh: str, sotiet_lt: int, sotiet_th: int) -> None:
        """
        Validate subject data before database operations.

        Args:
            mamh: Subject code
            tenmh: Subject name
            sotiet_lt: Theory hours
            sotiet_th: Practice hours

        Raises:
            HTTPException: If validation fails
        """
        validation_errors = []

        # Check for empty values
        if not mamh or not mamh.strip():
            validation_errors.append("Mã môn học không được để trống")

        if not tenmh or not tenmh.strip():
            validation_errors.append("Tên môn học không được để trống")

        # Check for negative values
        if sotiet_lt < 0:
            validation_errors.append("Số tiết lý thuyết không được âm")

        if sotiet_th < 0:
            validation_errors.append("Số tiết thực hành không được âm")

        # Check total hours
        if (sotiet_lt + sotiet_th) <= 0:
            validation_errors.append("Tổng số tiết phải lớn hơn 0")

        # If any errors, raise an exception with all messages
        if validation_errors:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="; ".join(validation_errors)
            )

    # Public API
    def list_monhoc(
        self,
        current_user: Dict[str, str],
        mamh: Optional[str] = None,
        tenmh: Optional[str] = None
    ) -> List[Dict]:
        """
        List subjects with optional filters.

        Args:
            current_user: The authenticated user
            mamh: Optional subject code filter
            tenmh: Optional subject name filter

        Returns:
            List of subject dictionaries

        Raises:
            HTTPException: If user doesn't have access or database error occurs
        """
        # Only allow PGV and KHOA roles, block SV role
        if not current_user or current_user.get("role") not in ALLOWED_ROLES:
            logger.warning(
                f"User with role {current_user.get('role', 'none')} attempted to list subjects")
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Bạn không có quyền xem danh sách môn học",
            )

        repo = None
        try:
            logger.info(
                f"Getting subject list with filters: mamh='{mamh}', tenmh='{tenmh}'")
            repo = MonHocRepository(current_user)
            return repo.list(mamh, tenmh)
        except Exception as err:
            logger.error(f"Error listing subjects: {err}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Lỗi khi lấy danh sách môn học"
            ) from err
        finally:
            if repo:
                repo.close_connection()

    def upsert_monhoc(
        self,
        current_user: Dict[str, str],
        mamh: str,
        tenmh: str,
        sotiet_lt: int,
        sotiet_th: int,
    ) -> None:
        """
        Create or update a subject.

        Args:
            current_user: The authenticated user
            mamh: Subject code
            tenmh: Subject name
            sotiet_lt: Theory hours
            sotiet_th: Practice hours

        Raises:
            HTTPException: For permission, validation, or database errors
        """
        # Check role permission
        self._ensure_pgv(current_user)

        # Validate input data
        self._validate_monhoc(mamh, tenmh, sotiet_lt, sotiet_th)

        repo = None
        try:
            logger.info(
                f"Upserting subject: {mamh}, {tenmh}, LT={sotiet_lt}, TH={sotiet_th}")
            repo = MonHocRepository(current_user)
            repo.upsert(mamh, tenmh, sotiet_lt, sotiet_th)
        except pyodbc.Error as err:
            # Extract error message from SQL Server
            msg = str(err).split(']')[-1].strip()
            logger.error(f"Error upserting subject {mamh}: {msg}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=msg or "Lỗi khi lưu môn học"
            ) from err
        except Exception as err:
            logger.error(f"Unexpected error upserting subject {mamh}: {err}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Lỗi hệ thống khi lưu môn học"
            ) from err
        finally:
            if repo:
                repo.close_connection()

    def delete_monhoc(self, current_user: Dict[str, str], mamh: str) -> None:
        """
        Delete a subject by code.

        Args:
            current_user: The authenticated user
            mamh: Subject code to delete

        Raises:
            HTTPException: For permission errors or if deletion fails
        """
        # Check role permission
        self._ensure_pgv(current_user)

        # Basic validation
        if not mamh or not mamh.strip():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Mã môn học không được để trống"
            )

        repo = None
        try:
            logger.info(f"Deleting subject: {mamh}")
            repo = MonHocRepository(current_user)
            repo.delete(mamh)
        except pyodbc.Error as err:
            # Extract the last token after ']': custom message from RAISERROR/THROW
            msg = str(err).split(']')[-1].strip()
            logger.warning(f"Cannot delete MONHOC {mamh}: {msg}")

            # Check for not found vs constraint violation
            if "not found" in msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Không tìm thấy môn học"
                ) from err
            else:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=msg or "Không thể xóa môn học do đã được sử dụng"
                ) from err
        except Exception as err:
            logger.error(f"Unexpected error deleting subject {mamh}: {err}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Lỗi hệ thống khi xóa môn học"
            ) from err
        finally:
            if repo:
                repo.close_connection()
