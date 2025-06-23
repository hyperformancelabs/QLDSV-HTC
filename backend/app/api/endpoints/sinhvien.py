"""Endpoints for SINHVIEN (student) management."""

from __future__ import annotations

import logging
from typing import Optional
from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query, Path, status
from fastapi.responses import JSONResponse

from app.schemas.sinhvien import (
    SinhVienResponse,
    SinhVienListResponse,
    SinhVienCreate,
    SinhVienUpdate,
)
from app.services.sinhvien import SinhVienService
from app.api.dependencies.auth import get_current_user, require_pgv, require_pgv_or_khoa

router = APIRouter()
logger = logging.getLogger("app.api.sinhvien")

service = SinhVienService()


@router.get(
    "/class/{malop}",
    response_model=SinhVienListResponse,
    summary="Danh sách sinh viên theo lớp",
    description="Lấy danh sách sinh viên theo lớp với phân trang, tìm kiếm và sắp xếp. PGV có thể xem tất cả, KHOA chỉ xem sinh viên thuộc khoa mình.",
    responses={
        200: {"description": "Danh sách sinh viên"},
        401: {"description": "Chưa đăng nhập"},
        403: {"description": "Không có quyền truy cập"},
        500: {"description": "Lỗi máy chủ"}
    }
)
async def list_sinhvien_by_class(
    malop: str = Path(..., description="Mã lớp"),
    page: int = Query(1, ge=1, description="Số trang"),
    page_size: int = Query(
        50, ge=1, le=100, description="Số bản ghi mỗi trang"),
    search: Optional[str] = Query(
        None, description="Từ khóa tìm kiếm (mã SV hoặc họ tên)"),
    sort_by: str = Query(
        "HO", description="Cột sắp xếp (HO, TEN, MASV, PHAI, NGAYSINH)"),
    sort_dir: str = Query("ASC", description="Hướng sắp xếp (ASC, DESC)"),
    user=Depends(require_pgv_or_khoa)
):
    """
    Lấy danh sách sinh viên theo lớp với phân trang.

    Parameters:
    - **malop**: Mã lớp
    - **page**: Số trang (bắt đầu từ 1)
    - **page_size**: Số bản ghi mỗi trang
    - **search**: Từ khóa tìm kiếm (mã SV hoặc họ tên)
    - **sort_by**: Cột sắp xếp (HO, TEN, MASV, PHAI, NGAYSINH)
    - **sort_dir**: Hướng sắp xếp (ASC, DESC)

    Quyền: PGV, KHOA
    """
    try:
        students, total = service.list_sinhvien_by_class(
            user, malop, page, page_size, search, sort_by, sort_dir
        )
        return {
            "data": students,
            "total": total,
            "page": page,
            "page_size": page_size
        }
    except Exception as e:
        logger.error(f"Error in list_sinhvien_by_class: {e}")
        if hasattr(e, 'status_code'):
            # If it's an HTTPException from the service, pass it through
            raise
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Lỗi khi lấy danh sách sinh viên"
        )


@router.post(
    "/",
    status_code=status.HTTP_201_CREATED,
    summary="Thêm sinh viên mới",
    description="Thêm mới sinh viên. Chỉ PGV có quyền.",
    responses={
        201: {"description": "Thêm thành công"},
        400: {"description": "Dữ liệu không hợp lệ"},
        401: {"description": "Chưa đăng nhập"},
        403: {"description": "Không có quyền"},
        500: {"description": "Lỗi máy chủ"}
    }
)
async def create_sinhvien(
    payload: dict,
    user=Depends(require_pgv)
):
    """
    Thêm mới sinh viên.

    Parameters:
    - **MASV**: Mã sinh viên (khóa chính)
    - **HO**: Họ sinh viên
    - **TEN**: Tên sinh viên
    - **MALOP**: Mã lớp sinh viên thuộc về
    - **PHAI**: Phái (Nam/Nữ)
    - **NGAYSINH**: Ngày sinh
    - **DIACHI**: Địa chỉ
    - **DANGHIHOC**: Trạng thái nghỉ học (mặc định: false)
    - **PASSWORD**: Mật khẩu (sẽ được băm)

    Quyền: PGV
    """
    try:
        # Log the received payload
        logger.info(f"Received create request")
        logger.info(f"Raw payload: {payload}")

        # Extract fields from the payload
        masv = payload.get("MASV")
        ho = payload.get("HO")
        ten = payload.get("TEN")
        malop = payload.get("MALOP")
        phai = payload.get("PHAI")
        ngaysinh_str = payload.get("NGAYSINH")
        diachi = payload.get("DIACHI")
        danghihoc = payload.get("DANGHIHOC", False)
        password = payload.get("PASSWORD", "123456")

        # Convert ngaysinh from string to date
        from datetime import datetime, timedelta
        try:
            ngaysinh = datetime.strptime(ngaysinh_str, "%Y-%m-%d").date()

            # Validate that the birth date is at most the current date minus 15 years
            min_birth_date = datetime.now().date() - timedelta(days=365 * 15)
            if ngaysinh > min_birth_date:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail="Ngày sinh phải cách đây ít nhất 15 năm"
                )

        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Invalid date format for NGAYSINH. Expected format: YYYY-MM-DD"
            )

        # Ensure phai is boolean
        if isinstance(phai, str):
            if phai.lower() in ('true', '1', 'yes', 'nữ'):
                phai = True
            elif phai.lower() in ('false', '0', 'no', 'nam'):
                phai = False
            else:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail=f"Invalid value for PHAI: {phai}. Must be a boolean or a string that can be converted to boolean."
                )

        # Validate required fields
        if not masv or not ho or not ten or not malop or phai is None or not ngaysinh or not diachi:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Missing required fields"
            )

        service.upsert_sinhvien(
            user,
            masv,
            ho,
            ten,
            malop,
            phai,
            ngaysinh,
            diachi,
            danghihoc,
            password,
        )
        return JSONResponse(
            {"message": "Thêm sinh viên thành công"},
            status_code=status.HTTP_201_CREATED
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in create_sinhvien: {e}")
        if hasattr(e, 'status_code'):
            # If it's an HTTPException from the service, pass it through
            raise
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Lỗi hệ thống khi thêm sinh viên"
        )


@router.put(
    "/{masv}",
    summary="Cập nhật sinh viên",
    description="Cập nhật thông tin sinh viên. Chỉ PGV có quyền.",
    responses={
        200: {"description": "Cập nhật thành công"},
        400: {"description": "Dữ liệu không hợp lệ"},
        401: {"description": "Chưa đăng nhập"},
        403: {"description": "Không có quyền"},
        404: {"description": "Không tìm thấy sinh viên"},
        500: {"description": "Lỗi máy chủ"}
    }
)
async def update_sinhvien(
    masv: str = Path(..., description="Mã sinh viên"),
    payload: dict = None,
    user=Depends(require_pgv)
):
    """
    Cập nhật thông tin sinh viên.

    Parameters:
    - **masv**: Mã sinh viên (path parameter)
    - **payload**: Dữ liệu cập nhật (request body)

    Quyền: PGV
    """
    try:
        # Log the received payload
        logger.info(f"Received update request for student {masv}")
        logger.info(f"Raw payload: {payload}")

        # Extract fields from the payload
        ho = payload.get("HO")
        ten = payload.get("TEN")
        malop = payload.get("MALOP")
        phai = payload.get("PHAI")
        ngaysinh_str = payload.get("NGAYSINH")
        diachi = payload.get("DIACHI")
        danghihoc = payload.get("DANGHIHOC", False)
        password = payload.get("PASSWORD")

        # Convert ngaysinh from string to date
        from datetime import datetime, timedelta
        try:
            ngaysinh = datetime.strptime(ngaysinh_str, "%Y-%m-%d").date()

            # Validate that the birth date is at most the current date minus 15 years
            min_birth_date = datetime.now().date() - timedelta(days=365 * 15)
            if ngaysinh > min_birth_date:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail="Ngày sinh phải cách đây ít nhất 15 năm"
                )

        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Invalid date format for NGAYSINH. Expected format: YYYY-MM-DD"
            )

        # Ensure phai is boolean
        if isinstance(phai, str):
            if phai.lower() in ('true', '1', 'yes', 'nữ'):
                phai = True
            elif phai.lower() in ('false', '0', 'no', 'nam'):
                phai = False
            else:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail=f"Invalid value for PHAI: {phai}. Must be a boolean or a string that can be converted to boolean."
                )

        # Validate required fields
        if not ho or not ten or not malop or phai is None or not ngaysinh or not diachi:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Missing required fields"
            )

        # Call the service
        service.upsert_sinhvien(
            user,
            masv,
            ho,
            ten,
            malop,
            phai,
            ngaysinh,
            diachi,
            danghihoc,
            password,
        )
        return {"message": "Cập nhật sinh viên thành công"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in update_sinhvien: {e}")
        if hasattr(e, 'status_code'):
            # If it's an HTTPException from the service, pass it through
            raise
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Lỗi hệ thống khi cập nhật sinh viên"
        )


@router.delete(
    "/{masv}",
    summary="Xóa sinh viên",
    description="Xóa sinh viên theo mã. Chỉ PGV có quyền.",
    responses={
        200: {"description": "Xóa thành công"},
        400: {"description": "Dữ liệu không hợp lệ"},
        401: {"description": "Chưa đăng nhập"},
        403: {"description": "Không có quyền"},
        404: {"description": "Không tìm thấy sinh viên"},
        409: {"description": "Không thể xóa do ràng buộc"},
        500: {"description": "Lỗi máy chủ"}
    }
)
async def delete_sinhvien(
    masv: str = Path(..., description="Mã sinh viên"),
    user=Depends(require_pgv)
):
    """
    Xóa sinh viên theo mã.

    Parameters:
    - **masv**: Mã sinh viên cần xóa

    Quyền: PGV
    """
    try:
        service.delete_sinhvien(user, masv)
        return {"message": "Xóa sinh viên thành công"}
    except Exception as e:
        logger.error(f"Error in delete_sinhvien: {e}")
        if hasattr(e, 'status_code'):
            # If it's an HTTPException from the service, pass it through
            raise
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Lỗi hệ thống khi xóa sinh viên"
        )
