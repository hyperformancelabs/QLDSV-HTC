"""API endpoints for LOPTINCHI (class sections) and DANGKY (registrations)."""

from __future__ import annotations

from typing import List, Dict, Optional

from fastapi import APIRouter, Depends, Query, Path, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

from app.api.dependencies.auth import get_current_user, check_role_permission
from app.schemas.loptinchi import (
    LopTinChiCreate,
    LopTinChiUpdate,
    LopTinChiCancel,
    LopTinChiRestore,
    LopTinChiFilter,
    LopTinChiResponse,
    DangKyCreate,
    DangKyCancel,
    DangKyResponse,
    StudentInfo
)
from app.services.loptinchi import LopTinChiService

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


@router.get("/", response_model=List[LopTinChiResponse])
async def get_loptinchi_list(
    nienkhoa: Optional[str] = Query(
        None, description="Niên khóa (format: YYYY-YYYY)"),
    hocky: Optional[int] = Query(None, description="Học kỳ (1-3)", ge=1, le=3),
    makhoa: Optional[str] = Query(None, description="Mã khoa"),
    only_available: bool = Query(False, description="Chỉ lấy lớp chưa hủy"),
    current_user: Dict = Depends(get_current_user)
):
    """
    Get a list of class sections based on filters.

    This endpoint can be accessed by all authenticated users.
    """
    # Create filter object
    filters = LopTinChiFilter(
        nienkhoa=nienkhoa,
        hocky=hocky,
        makhoa=makhoa,
        only_available=only_available
    )

    # Create service and get data
    service = LopTinChiService(current_user)
    return service.get_loptinchi_list(filters)


@router.post("/", response_model=Dict, status_code=status.HTTP_201_CREATED)
async def create_loptinchi(
    loptinchi_data: LopTinChiCreate,
    current_user: Dict = Depends(get_current_user)
):
    """
    Create a new class section.

    This endpoint can only be accessed by users with PGV role.
    """
    # Check role permission
    if current_user.get("role") != "pgv_role":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bạn không có quyền truy cập chức năng này"
        )

    # Create service and process request
    service = LopTinChiService(current_user)
    return service.create_loptinchi(loptinchi_data)


@router.put("/{maltc}", response_model=Dict)
async def update_loptinchi(
    maltc: int = Path(..., description="Mã lớp tín chỉ", ge=1),
    loptinchi_data: LopTinChiCreate = None,
    current_user: Dict = Depends(get_current_user)
):
    """
    Update an existing class section.

    This endpoint can only be accessed by users with PGV role.
    """
    # Check role permission
    if current_user.get("role") != "pgv_role":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bạn không có quyền truy cập chức năng này"
        )

    # Create full update object with path parameter
    update_data = LopTinChiUpdate(
        maltc=maltc,
        **loptinchi_data.dict()
    )

    # Create service and process request
    service = LopTinChiService(current_user)
    return service.update_loptinchi(update_data)


@router.delete("/{maltc}", response_model=Dict)
async def cancel_loptinchi(
    maltc: int = Path(..., description="Mã lớp tín chỉ", ge=1),
    current_user: Dict = Depends(get_current_user)
):
    """
    Cancel a class section (soft delete).

    This endpoint can only be accessed by users with PGV role.
    """
    # Check role permission
    if current_user.get("role") != "pgv_role":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bạn không có quyền truy cập chức năng này"
        )

    # Create service and process request
    service = LopTinChiService(current_user)
    return service.cancel_loptinchi(LopTinChiCancel(maltc=maltc))


@router.post("/{maltc}/restore", response_model=Dict)
async def restore_loptinchi(
    maltc: int = Path(..., description="Mã lớp tín chỉ", ge=1),
    current_user: Dict = Depends(get_current_user)
):
    """
    Restore a previously canceled class section.

    This endpoint can only be accessed by users with PGV role.
    """
    # Check role permission
    if current_user.get("role") != "pgv_role":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bạn không có quyền truy cập chức năng này"
        )

    # Create service and process request
    service = LopTinChiService(current_user)
    return service.restore_loptinchi(LopTinChiRestore(maltc=maltc))


@router.post("/register", response_model=Dict)
async def register_course(
    registration_data: DangKyCreate,
    current_user: Dict = Depends(get_current_user)
):
    """
    Register a student for a class section.

    This endpoint can be accessed by users with PGV role or SV role (if registering themselves).
    """
    # Check if user has PGV role or is a student registering themselves
    user_role = current_user.get("role")
    if user_role != "pgv_role" and user_role == "sv_role":
        # Student can only register themselves
        if registration_data.masv != current_user.get("username"):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Sinh viên chỉ được phép đăng ký cho chính mình"
            )
    elif user_role != "pgv_role":
        # Neither PGV nor student - forbidden
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Không có quyền đăng ký lớp tín chỉ"
        )

    # Create service and process request
    service = LopTinChiService(current_user)
    return service.register_course(registration_data)


@router.post("/cancel-registration", response_model=Dict)
async def cancel_registration(
    cancel_data: DangKyCancel,
    current_user: Dict = Depends(get_current_user)
):
    """
    Cancel a student's registration for a class section.

    This endpoint can be accessed by users with PGV role or SV role (if canceling their own registration).
    """
    # Check if user has PGV role or is a student canceling their own registration
    user_role = current_user.get("role")
    if user_role != "pgv_role" and user_role == "sv_role":
        # Student can only cancel their own registration
        if cancel_data.masv != current_user.get("username"):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Sinh viên chỉ được phép hủy đăng ký của chính mình"
            )
    elif user_role != "pgv_role":
        # Neither PGV nor student - forbidden
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Không có quyền hủy đăng ký lớp tín chỉ"
        )

    # Create service and process request
    service = LopTinChiService(current_user)
    return service.cancel_registration(cancel_data)


@router.get("/student/{masv}/registrations", response_model=List[DangKyResponse])
async def get_student_registrations(
    masv: str = Path(..., description="Mã sinh viên"),
    current_user: Dict = Depends(get_current_user)
):
    """
    Get a list of class sections a student has registered for.

    This endpoint can be accessed by users with PGV/KHOA role or SV role (if viewing their own registrations).
    """
    # Check if user has PGV/KHOA role or is a student viewing their own registrations
    user_role = current_user.get("role")
    if user_role != "pgv_role" and user_role != "khoa_role" and user_role == "sv_role":
        # Student can only view their own registrations
        if masv != current_user.get("username"):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Sinh viên chỉ được phép xem đăng ký của chính mình"
            )
    elif user_role != "pgv_role" and user_role != "khoa_role" and user_role != "sv_role":
        # No valid role - forbidden
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Không có quyền xem đăng ký lớp tín chỉ"
        )

    # Create service and get data
    service = LopTinChiService(current_user)
    return service.get_student_registrations(masv)


@router.get("/student/{masv}/info", response_model=StudentInfo)
async def get_student_info(
    masv: str = Path(..., description="Mã sinh viên"),
    current_user: Dict = Depends(get_current_user)
):
    """
    Get basic information about a student.

    This endpoint can be accessed by users with PGV/KHOA role or SV role (if viewing their own info).
    """
    # Check if user has PGV/KHOA role or is a student viewing their own info
    user_role = current_user.get("role")
    if user_role != "pgv_role" and user_role != "khoa_role" and user_role == "sv_role":
        # Student can only view their own info
        if masv != current_user.get("username"):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Sinh viên chỉ được phép xem thông tin của chính mình"
            )
    elif user_role != "pgv_role" and user_role != "khoa_role" and user_role != "sv_role":
        # No valid role - forbidden
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Không có quyền xem thông tin sinh viên"
        )

    # Create service and get data
    service = LopTinChiService(current_user)
    return service.get_student_info(masv)
