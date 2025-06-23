"""Business logic for SINHVIEN (student) operations."""

from __future__ import annotations

import logging
from typing import List, Dict, Optional, Tuple
from datetime import date

from fastapi import HTTPException, status
import pyodbc

from app.db.repositories.sinhvien import SinhVienRepository
from app.db.repositories.lop import LopRepository

logger = logging.getLogger("app.services.sinhvien")

# Constants for role-based access control
REQUIRED_ROLE = "pgv_role"  # Only PGV can modify
ALLOWED_ROLES = ["pgv_role", "khoa_role"]  # PGV and KHOA can view


class SinhVienService:
    """Service layer for SINHVIEN (student) operations."""

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

    def _check_lop_access(self, current_user: Dict[str, str], malop: str) -> None:
        """
        Check if user has access to the specified class.
        For KHOA users, they can only access classes in their department.

        Args:
            current_user: The authenticated user dictionary
            malop: Class code to check

        Raises:
            HTTPException: If user doesn't have access to the class
        """
        # PGV can access all classes
        if current_user.get("role") == REQUIRED_ROLE:
            return

        # For KHOA role, check if class belongs to their department
        if current_user.get("role") == "khoa_role":
            user_makhoa = current_user.get("makhoa")
            if not user_makhoa:
                logger.error(
                    f"KHOA user without makhoa attribute: {current_user}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Lỗi xác thực khoa"
                )

            # Get class info to check makhoa
            repo = None
            try:
                repo = LopRepository(current_user)
                classes = repo.list_by_khoa(user_makhoa)

                # Check if class belongs to user's khoa
                if not any(c["MALOP"] == malop for c in classes):
                    logger.warning(
                        f"User from khoa {user_makhoa} attempted to access class {malop}")
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail="Bạn không có quyền truy cập lớp này"
                    )
            except HTTPException:
                raise
            except Exception as err:
                logger.error(f"Error checking class access: {err}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Lỗi kiểm tra quyền truy cập lớp"
                ) from err
            finally:
                if repo:
                    repo.close_connection()
        else:
            # Other roles don't have access
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Bạn không có quyền truy cập"
            )

    def _validate_sinhvien(self, masv: str, ho: str, ten: str, malop: str,
                           phai: bool, ngaysinh: date, diachi: str) -> None:
        """
        Validate student data before database operations.

        Args:
            masv: Student code
            ho: Last name
            ten: First name
            malop: Class code
            phai: Gender (boolean)
            ngaysinh: Birth date
            diachi: Address

        Raises:
            HTTPException: If validation fails
        """
        validation_errors = []

        # Check for empty values
        if not masv or not masv.strip():
            validation_errors.append("Mã sinh viên không được để trống")

        if not ho or not ho.strip():
            validation_errors.append("Họ sinh viên không được để trống")

        if not ten or not ten.strip():
            validation_errors.append("Tên sinh viên không được để trống")

        if not malop or not malop.strip():
            validation_errors.append("Mã lớp không được để trống")

        if phai is None:  # Check if phai is provided
            validation_errors.append("Phái không được để trống")

        if not diachi or not diachi.strip():
            validation_errors.append("Địa chỉ không được để trống")

        # Validate date
        if not ngaysinh:
            validation_errors.append("Ngày sinh không được để trống")

        # If any errors, raise an exception with all messages
        if validation_errors:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="; ".join(validation_errors)
            )

    # Public API
    def list_sinhvien_by_class(
        self,
        current_user: Dict[str, str],
        malop: str,
        page: int = 1,
        page_size: int = 50,
        search: Optional[str] = None,
        sort_by: str = "HO",
        sort_dir: str = "ASC"
    ) -> Tuple[List[Dict], int]:
        """
        List students with pagination by class.

        Args:
            current_user: The authenticated user
            malop: Class code filter
            page: Page number (1-based)
            page_size: Records per page
            search: Optional search term
            sort_by: Column to sort by
            sort_dir: Sort direction ('ASC' or 'DESC')

        Returns:
            Tuple of (list of student dictionaries, total count)

        Raises:
            HTTPException: If user doesn't have access or database error occurs
        """
        # Only allow PGV and KHOA roles
        if not current_user or current_user.get("role") not in ALLOWED_ROLES:
            logger.warning(
                f"User with role {current_user.get('role', 'none')} attempted to list students")
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Bạn không có quyền xem danh sách sinh viên",
            )

        # Check if user has access to the class
        self._check_lop_access(current_user, malop)

        repo = None
        try:
            logger.info(
                f"Getting student list for class: {malop}, page={page}, size={page_size}")
            repo = SinhVienRepository(current_user)
            students, total = repo.list_by_class(
                malop, page, page_size, search, sort_by, sort_dir)
            return students, total
        except Exception as err:
            logger.error(f"Error listing students: {err}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Lỗi khi lấy danh sách sinh viên"
            ) from err
        finally:
            if repo:
                repo.close_connection()

    def upsert_sinhvien(
        self,
        current_user: Dict[str, str],
        masv: str,
        ho: str,
        ten: str,
        malop: str,
        phai: bool,
        ngaysinh: date,
        diachi: str,
        danghihoc: bool = False,
        password: Optional[str] = None,
    ) -> None:
        """
        Create or update a student.

        Args:
            current_user: The authenticated user
            masv: Student code
            ho: Last name
            ten: First name
            malop: Class code
            phai: Gender (False=Nam, True=Nữ)
            ngaysinh: Birth date
            diachi: Address
            danghihoc: Study status
            password: Optional password (will not be hashed)

        Raises:
            HTTPException: For permission, validation, or database errors
        """
        # Check role permission
        self._ensure_pgv(current_user)

        # Validate input data
        self._validate_sinhvien(masv, ho, ten, malop, phai, ngaysinh, diachi)

        # Pass password directly without hashing
        hashed_password = password

        repo = None
        try:
            logger.info(
                f"Upserting student: {masv}, {ho} {ten}, class={malop}")
            repo = SinhVienRepository(current_user)
            repo.upsert(masv, ho, ten, malop, phai, ngaysinh,
                        diachi, danghihoc, hashed_password)
        except pyodbc.Error as err:
            # Extract error message from SQL Server
            msg = str(err).split(']')[-1].strip()
            logger.error(f"Error upserting student {masv}: {msg}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=msg or "Lỗi khi lưu sinh viên"
            ) from err
        except Exception as err:
            logger.error(f"Unexpected error upserting student {masv}: {err}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Lỗi hệ thống khi lưu sinh viên"
            ) from err
        finally:
            if repo:
                repo.close_connection()

    def delete_sinhvien(self, current_user: Dict[str, str], masv: str) -> None:
        """
        Delete a student by code.

        Args:
            current_user: The authenticated user
            masv: Student code to delete

        Raises:
            HTTPException: For permission errors or if deletion fails
        """
        # Check role permission
        self._ensure_pgv(current_user)

        # Basic validation
        if not masv or not masv.strip():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Mã sinh viên không được để trống"
            )

        repo = None
        try:
            logger.info(f"Deleting student: {masv}")
            repo = SinhVienRepository(current_user)
            repo.delete(masv)
        except pyodbc.Error as err:
            # Extract the last token after ']': custom message from RAISERROR/THROW
            msg = str(err).split(']')[-1].strip()
            logger.warning(f"Cannot delete SINHVIEN {masv}: {msg}")

            # Check for not found vs constraint violation
            if "không tồn tại" in msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Không tìm thấy sinh viên"
                ) from err
            else:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=msg or "Không thể xóa sinh viên"
                ) from err
        except Exception as err:
            logger.error(f"Unexpected error deleting student {masv}: {err}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Lỗi hệ thống khi xóa sinh viên"
            ) from err
        finally:
            if repo:
                repo.close_connection()
