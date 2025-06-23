"""Business logic for LOP (class) operations."""

from __future__ import annotations

import logging
from typing import List, Dict, Optional

from fastapi import HTTPException, status
import pyodbc

from app.db.repositories.lop import LopRepository
from app.schemas.lop import LopFilters

logger = logging.getLogger("app.services.lop")

# Constants for role-based access control
REQUIRED_ROLE = "pgv_role"  # Only PGV can modify
ALLOWED_ROLES = ["pgv_role", "khoa_role"]  # PGV and KHOA can view


class LopService:
    """Service layer for LOP (class) operations."""

    def __init__(self) -> None:
        """Initialize the service."""
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

    def _validate_lop(self, malop: str, tenlop: str, khoahoc: str, makhoa: str) -> None:
        """
        Validate class data before database operations.

        Args:
            malop: Class code
            tenlop: Class name
            khoahoc: Academic years
            makhoa: Khoa code

        Raises:
            HTTPException: If validation fails
        """
        validation_errors = []

        # Check for empty values
        if not malop or not malop.strip():
            validation_errors.append("Mã lớp không được để trống")

        if not tenlop or not tenlop.strip():
            validation_errors.append("Tên lớp không được để trống")

        if not khoahoc or not khoahoc.strip():
            validation_errors.append("Khóa học không được để trống")

        if not makhoa or not makhoa.strip():
            validation_errors.append("Mã khoa không được để trống")

        # If any errors, raise an exception with all messages
        if validation_errors:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="; ".join(validation_errors)
            )

    # Public API
    def list_lop_by_khoa(
        self,
        current_user: Dict[str, str],
        filters: LopFilters = None
    ) -> List[Dict]:
        """
        List classes with optional filters.

        Args:
            current_user: The authenticated user
            filters: Optional filters for makhoa and khoahoc

        Returns:
            List of class dictionaries with student count

        Raises:
            HTTPException: If user doesn't have access or database error occurs
        """
        # Only allow PGV and KHOA roles
        if not current_user or current_user.get("role") not in ALLOWED_ROLES:
            logger.warning(
                f"User with role {current_user.get('role', 'none')} attempted to list classes")
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Bạn không có quyền xem danh sách lớp",
            )

        # Initialize filters if not provided
        if not filters:
            filters = LopFilters()

        makhoa = filters.makhoa
        khoahoc = filters.khoahoc

        # For KHOA role, force filter by their own khoa
        if current_user.get("role") == "khoa_role":
            makhoa = current_user.get("makhoa")
            if not makhoa:
                logger.error(
                    f"KHOA user without makhoa attribute: {current_user}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Lỗi xác thực khoa"
                )

        repo = None
        try:
            logger.info(
                f"Getting class list with filters: makhoa='{makhoa}', khoahoc='{khoahoc}'")
            repo = LopRepository(current_user)
            return repo.list_by_khoa(makhoa, khoahoc)
        except Exception as err:
            logger.error(f"Error listing classes: {err}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Lỗi khi lấy danh sách lớp"
            ) from err
        finally:
            if repo:
                repo.close_connection()

    def check_has_students(self, current_user: Dict[str, str], malop: str) -> Dict[str, int]:
        """
        Check if a class has students.

        Args:
            current_user: The authenticated user
            malop: Class code to check

        Returns:
            Dictionary with student count

        Raises:
            HTTPException: For permission errors
        """
        # Only allow PGV and KHOA roles
        if not current_user or current_user.get("role") not in ALLOWED_ROLES:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Bạn không có quyền thực hiện thao tác này"
            )

        # Basic validation
        if not malop or not malop.strip():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Mã lớp không được để trống"
            )

        repo = None
        try:
            repo = LopRepository(current_user)
            student_count = repo.has_students(malop)
            return {"student_count": student_count}
        except Exception as err:
            logger.error(f"Error checking students for class {malop}: {err}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Lỗi khi kiểm tra số sinh viên"
            ) from err
        finally:
            if repo:
                repo.close_connection()

    def upsert_lop(
        self,
        current_user: Dict[str, str],
        malop: str,
        tenlop: str,
        khoahoc: str,
        makhoa: str,
    ) -> None:
        """
        Create or update a class.

        Args:
            current_user: The authenticated user
            malop: Class code
            tenlop: Class name
            khoahoc: Academic years
            makhoa: Khoa code

        Raises:
            HTTPException: For permission, validation, or database errors
        """
        # Check role permission
        self._ensure_pgv(current_user)

        # Validate input data
        self._validate_lop(malop, tenlop, khoahoc, makhoa)

        repo = None
        try:
            logger.info(
                f"Upserting class: {malop}, {tenlop}, {khoahoc}, {makhoa}")
            repo = LopRepository(current_user)
            repo.upsert(malop, tenlop, khoahoc, makhoa)
        except pyodbc.Error as err:
            # Extract error message from SQL Server
            msg = str(err).split(']')[-1].strip()
            logger.error(f"Error upserting class {malop}: {msg}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=msg or "Lỗi khi lưu lớp"
            ) from err
        except Exception as err:
            logger.error(f"Unexpected error upserting class {malop}: {err}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Lỗi hệ thống khi lưu lớp"
            ) from err
        finally:
            if repo:
                repo.close_connection()

    def delete_lop(self, current_user: Dict[str, str], malop: str) -> None:
        """
        Delete a class by code.

        Args:
            current_user: The authenticated user
            malop: Class code to delete

        Raises:
            HTTPException: For permission errors or if deletion fails
        """
        # Check role permission
        self._ensure_pgv(current_user)

        # Basic validation
        if not malop or not malop.strip():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Mã lớp không được để trống"
            )

        repo = None
        try:
            logger.info(f"Deleting class: {malop}")
            repo = LopRepository(current_user)

            # Check if class has students before attempting to delete
            student_count = repo.has_students(malop)
            if student_count > 0:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=f"Không thể xóa lớp vì đã có {student_count} sinh viên"
                )

            repo.delete(malop)
        except HTTPException:
            raise
        except pyodbc.Error as err:
            # Extract the last token after ']': custom message from RAISERROR/THROW
            msg = str(err).split(']')[-1].strip()
            logger.warning(f"Cannot delete LOP {malop}: {msg}")

            # Check for not found vs constraint violation
            if "không tồn tại" in msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Không tìm thấy lớp"
                ) from err
            else:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=msg or "Không thể xóa lớp do đã có sinh viên"
                ) from err
        except Exception as err:
            logger.error(f"Unexpected error deleting class {malop}: {err}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Lỗi hệ thống khi xóa lớp"
            ) from err
        finally:
            if repo:
                repo.close_connection()
