"""Service layer for LOPTINCHI (class sections) and DANGKY (registrations)."""

from __future__ import annotations

import logging
from typing import List, Dict, Optional, Union, Tuple

import pyodbc
from fastapi import HTTPException, status

from app.db.connection import get_connection
from app.db.repositories.loptinchi import LopTinChiRepository
from app.schemas.loptinchi import (
    LopTinChiCreate,
    LopTinChiUpdate,
    LopTinChiCancel,
    LopTinChiRestore,
    LopTinChiFilter,
    DangKyCreate,
    DangKyCancel,
    StudentInfo
)

logger = logging.getLogger("app.services.loptinchi")


class LopTinChiService:
    """Service for managing LOPTINCHI (class sections) and DANGKY (registrations)."""

    def __init__(self, user: Dict[str, str]):
        """
        Initialize the service with a repository.

        Args:
            user: User information from the session
        """
        self.user = user

        # Use default connection for student users since they don't have direct DB access
        if user.get("role") == "sv_role":
            # Use default connection for students
            conn = get_connection()
            self.repository = LopTinChiRepository(conn=conn)
        else:
            # Use user credentials for other roles
            self.repository = LopTinChiRepository(user=user)

    def get_loptinchi_list(self, filters: LopTinChiFilter) -> List[Dict]:
        """
        Get a list of class sections based on filters.

        Args:
            filters: Filter criteria for class sections

        Returns:
            List of class section dictionaries

        Raises:
            HTTPException: On database errors or other issues
        """
        try:
            return self.repository.list_loptinchi(
                nienkhoa=filters.nienkhoa,
                hocky=filters.hocky,
                makhoa=filters.makhoa,
                only_available=filters.only_available
            )
        except pyodbc.Error as err:
            error_msg = str(err)
            logger.error(f"Database error in get_loptinchi_list: {error_msg}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi khi lấy danh sách lớp tín chỉ: {error_msg}"
            )

    def create_loptinchi(self, data: LopTinChiCreate) -> Dict:
        """
        Create a new class section.

        Args:
            data: Class section creation data

        Returns:
            Dictionary with success message and new class section ID

        Raises:
            HTTPException: On database errors or validation issues
        """
        try:
            maltc = self.repository.create_loptinchi(
                nienkhoa=data.nienkhoa,
                hocky=data.hocky,
                mamh=data.mamh,
                nhom=data.nhom,
                magv=data.magv,
                makhoa=data.makhoa,
                sosvtoithieu=data.sosvtoithieu
            )
            return {
                "message": "Tạo lớp tín chỉ thành công",
                "maltc": maltc
            }
        except pyodbc.Error as err:
            error_msg = str(err)
            logger.error(f"Database error in create_loptinchi: {error_msg}")

            # Check for common errors
            if "past semester" in error_msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Không thể tạo lớp tín chỉ cho học kỳ đã qua"
                )
            elif "duplicate" in error_msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Lớp tín chỉ với thông tin này đã tồn tại"
                )
            elif "foreign key" in error_msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Thông tin tham chiếu (môn học, giảng viên, khoa) không hợp lệ"
                )

            # Generic error
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi khi tạo lớp tín chỉ: {error_msg}"
            )

    def update_loptinchi(self, data: LopTinChiUpdate) -> Dict:
        """
        Update an existing class section.

        Args:
            data: Class section update data including ID

        Returns:
            Dictionary with success message

        Raises:
            HTTPException: On database errors or validation issues
        """
        try:
            self.repository.update_loptinchi(
                maltc=data.maltc,
                nienkhoa=data.nienkhoa,
                hocky=data.hocky,
                mamh=data.mamh,
                nhom=data.nhom,
                magv=data.magv,
                makhoa=data.makhoa,
                sosvtoithieu=data.sosvtoithieu
            )
            return {"message": f"Cập nhật lớp tín chỉ {data.maltc} thành công"}
        except pyodbc.Error as err:
            error_msg = str(err)
            logger.error(f"Database error in update_loptinchi: {error_msg}")

            # Check for common errors
            if "past semester" in error_msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Không thể cập nhật lớp tín chỉ cho học kỳ đã qua"
                )
            elif "not found" in error_msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Không tìm thấy lớp tín chỉ với mã {data.maltc}"
                )
            elif "duplicate" in error_msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Lớp tín chỉ với thông tin này đã tồn tại"
                )
            elif "foreign key" in error_msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Thông tin tham chiếu (môn học, giảng viên, khoa) không hợp lệ"
                )

            # Generic error
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi khi cập nhật lớp tín chỉ: {error_msg}"
            )

    def cancel_loptinchi(self, data: LopTinChiCancel) -> Dict:
        """
        Cancel a class section (soft delete).

        Args:
            data: Class section cancellation data with ID

        Returns:
            Dictionary with success message

        Raises:
            HTTPException: On database errors or validation issues
        """
        try:
            self.repository.cancel_loptinchi(data.maltc)
            return {"message": f"Hủy lớp tín chỉ {data.maltc} thành công"}
        except pyodbc.Error as err:
            error_msg = str(err)
            logger.error(f"Database error in cancel_loptinchi: {error_msg}")

            # Check for common errors
            if "past semester" in error_msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Không thể hủy lớp tín chỉ cho học kỳ đã qua"
                )
            elif "not found" in error_msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Không tìm thấy lớp tín chỉ với mã {data.maltc}"
                )
            elif "already canceled" in error_msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Lớp tín chỉ {data.maltc} đã bị hủy trước đó"
                )

            # Generic error
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi khi hủy lớp tín chỉ: {error_msg}"
            )

    def restore_loptinchi(self, data: LopTinChiRestore) -> Dict:
        """
        Restore a previously canceled class section.

        Args:
            data: Class section restoration data with ID

        Returns:
            Dictionary with success message

        Raises:
            HTTPException: On database errors or validation issues
        """
        try:
            self.repository.restore_loptinchi(data.maltc)
            return {"message": f"Khôi phục lớp tín chỉ {data.maltc} thành công"}
        except pyodbc.Error as err:
            error_msg = str(err)
            logger.error(f"Database error in restore_loptinchi: {error_msg}")

            # Check for common errors
            if "past semester" in error_msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Không thể khôi phục lớp tín chỉ cho học kỳ đã qua"
                )
            elif "not found" in error_msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Không tìm thấy lớp tín chỉ với mã {data.maltc}"
                )
            elif "not canceled" in error_msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Lớp tín chỉ {data.maltc} chưa bị hủy"
                )

            # Generic error
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi khi khôi phục lớp tín chỉ: {error_msg}"
            )

    def register_course(self, data: DangKyCreate) -> Dict:
        """
        Register a student for a class section.

        Args:
            data: Registration data with student ID and class section ID

        Returns:
            Dictionary with success message

        Raises:
            HTTPException: On database errors or validation issues
        """
        try:
            self.repository.register_course(data.masv, data.maltc)
            return {
                "message": f"Đăng ký lớp tín chỉ {data.maltc} cho sinh viên {data.masv} thành công"
            }
        except pyodbc.Error as err:
            error_msg = str(err)
            logger.error(f"Database error in register_course: {error_msg}")

            # Check for common errors
            if "past semester" in error_msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Không thể đăng ký lớp tín chỉ cho học kỳ đã qua"
                )
            elif "class not found" in error_msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Không tìm thấy lớp tín chỉ với mã {data.maltc}"
                )
            elif "student not found" in error_msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Không tìm thấy sinh viên với mã {data.masv}"
                )
            elif "already registered" in error_msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Sinh viên {data.masv} đã đăng ký lớp tín chỉ {data.maltc}"
                )
            elif "class canceled" in error_msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Lớp tín chỉ {data.maltc} đã bị hủy"
                )
            elif "registration period" in error_msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Ngoài thời gian đăng ký"
                )

            # Generic error
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi khi đăng ký lớp tín chỉ: {error_msg}"
            )

    def cancel_registration(self, data: DangKyCancel) -> Dict:
        """
        Cancel a student's registration for a class section.

        Args:
            data: Cancellation data with student ID and class section ID

        Returns:
            Dictionary with success message

        Raises:
            HTTPException: On database errors or validation issues
        """
        try:
            self.repository.cancel_registration(data.masv, data.maltc)
            return {
                "message": f"Hủy đăng ký lớp tín chỉ {data.maltc} cho sinh viên {data.masv} thành công"
            }
        except pyodbc.Error as err:
            error_msg = str(err)
            logger.error(f"Database error in cancel_registration: {error_msg}")

            # Check for common errors
            if "past semester" in error_msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Không thể hủy đăng ký lớp tín chỉ cho học kỳ đã qua"
                )
            elif "not registered" in error_msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Sinh viên {data.masv} chưa đăng ký lớp tín chỉ {data.maltc}"
                )
            elif "already canceled" in error_msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Đăng ký lớp tín chỉ {data.maltc} của sinh viên {data.masv} đã bị hủy trước đó"
                )
            elif "registration period" in error_msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Ngoài thời gian đăng ký"
                )

            # Generic error
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi khi hủy đăng ký lớp tín chỉ: {error_msg}"
            )

    def get_student_registrations(self, masv: str) -> List[Dict]:
        """
        Get a list of class sections a student has registered for.

        Args:
            masv: Student ID

        Returns:
            List of registration dictionaries with class section information

        Raises:
            HTTPException: On database errors or if student not found
        """
        try:
            registrations = self.repository.list_student_registrations(masv)
            return registrations
        except pyodbc.Error as err:
            error_msg = str(err)
            logger.error(
                f"Database error in get_student_registrations: {error_msg}")

            # Check for common errors
            if "student not found" in error_msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Không tìm thấy sinh viên với mã {masv}"
                )

            # Generic error
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi khi lấy danh sách đăng ký: {error_msg}"
            )

    def get_student_info(self, masv: str) -> StudentInfo:
        """
        Get basic information about a student.

        Args:
            masv: Student ID

        Returns:
            StudentInfo object with student information

        Raises:
            HTTPException: On database errors or if student not found
        """
        try:
            student_data = self.repository.get_student_info(masv)
            if not student_data:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Không tìm thấy sinh viên với mã {masv}"
                )
            return StudentInfo(**student_data)
        except pyodbc.Error as err:
            error_msg = str(err)
            logger.error(f"Database error in get_student_info: {error_msg}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi khi lấy thông tin sinh viên: {error_msg}"
            )

    def __del__(self):
        """Clean up resources."""
        if hasattr(self, 'repository'):
            self.repository.close_connection()
