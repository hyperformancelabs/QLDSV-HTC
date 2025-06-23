"""Endpoints for LOP (class) management."""

from __future__ import annotations

import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status, Query
from fastapi.responses import JSONResponse

from app.schemas.lop import (
    LopResponse,
    LopListResponse,
    LopCreateUpdate,
    LopFilters,
)
from app.services.lop import LopService
from app.api.dependencies.auth import get_current_user, require_pgv, require_pgv_or_khoa

router = APIRouter()
logger = logging.getLogger("app.api.lop")

service = LopService()


@router.get(
    "/",
    response_model=LopListResponse,
    summary="Danh sách lớp",
    description="Lấy danh sách lớp theo khoa và khóa học. PGV có thể xem tất cả, KHOA chỉ xem lớp thuộc khoa mình.",
    responses={
        200: {"description": "Danh sách lớp"},
        401: {"description": "Chưa đăng nhập"},
        403: {"description": "Không có quyền truy cập"},
        500: {"description": "Lỗi máy chủ"}
    }
)
async def list_lop(
    makhoa: Optional[str] = None,
    khoahoc: Optional[str] = None,
    user=Depends(require_pgv_or_khoa)
):
    """
    Lấy danh sách lớp theo khoa và khóa học.

    Parameters:
    - **makhoa**: Mã khoa (không bắt buộc cho PGV, bắt buộc cho KHOA)
    - **khoahoc**: Khóa học (vd: 2021-2025) (không bắt buộc)

    Quyền: PGV, KHOA
    """
    try:
        filters = LopFilters(makhoa=makhoa, khoahoc=khoahoc)
        data = service.list_lop_by_khoa(user, filters)
        return {"data": data}
    except Exception as e:
        logger.error(f"Error in list_lop: {e}")
        if hasattr(e, 'status_code'):
            # If it's an HTTPException from the service, pass it through
            raise
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Lỗi khi lấy danh sách lớp"
        )


@router.get(
    "/{malop}/student-count",
    summary="Kiểm tra số lượng sinh viên",
    description="Kiểm tra xem lớp có sinh viên không và trả về số lượng sinh viên.",
    responses={
        200: {"description": "Số lượng sinh viên trong lớp"},
        401: {"description": "Chưa đăng nhập"},
        403: {"description": "Không có quyền truy cập"},
        500: {"description": "Lỗi máy chủ"}
    }
)
async def check_has_students(
    malop: str,
    user=Depends(require_pgv_or_khoa)
):
    """
    Kiểm tra số lượng sinh viên trong lớp.

    Parameters:
    - **malop**: Mã lớp cần kiểm tra

    Quyền: PGV, KHOA
    """
    try:
        return service.check_has_students(user, malop)
    except Exception as e:
        logger.error(f"Error in check_has_students: {e}")
        if hasattr(e, 'status_code'):
            raise
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Lỗi khi kiểm tra số sinh viên"
        )


@router.post(
    "/",
    status_code=status.HTTP_201_CREATED,
    summary="Thêm/Cập nhật lớp",
    description="Thêm mới hoặc cập nhật lớp nếu đã tồn tại. Chỉ PGV có quyền.",
    responses={
        201: {"description": "Thêm/cập nhật thành công"},
        400: {"description": "Dữ liệu không hợp lệ"},
        401: {"description": "Chưa đăng nhập"},
        403: {"description": "Không có quyền"},
        500: {"description": "Lỗi máy chủ"}
    }
)
async def upsert_lop(
    payload: LopCreateUpdate,
    user=Depends(require_pgv)
):
    """
    Thêm mới hoặc cập nhật lớp.

    Parameters:
    - **MALOP**: Mã lớp (khóa chính)
    - **TENLOP**: Tên lớp (phải duy nhất)
    - **KHOAHOC**: Khóa học (vd: 2021-2025)
    - **MAKHOA**: Mã khoa quản lý lớp

    Quyền: PGV
    """
    try:
        service.upsert_lop(
            user,
            payload.malop,
            payload.tenlop,
            payload.khoahoc,
            payload.makhoa,
        )
        return JSONResponse(
            {"message": "Ghi thành công"},
            status_code=status.HTTP_201_CREATED
        )
    except Exception as e:
        logger.error(f"Error in upsert_lop: {e}")
        if hasattr(e, 'status_code'):
            # If it's an HTTPException from the service, pass it through
            raise
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Lỗi hệ thống khi lưu lớp"
        )


@router.delete(
    "/{malop}",
    summary="Xóa lớp",
    description="Xóa lớp theo mã. Chỉ thành công nếu lớp không có sinh viên. Chỉ PGV có quyền.",
    responses={
        200: {"description": "Xóa thành công"},
        400: {"description": "Dữ liệu không hợp lệ"},
        401: {"description": "Chưa đăng nhập"},
        403: {"description": "Không có quyền"},
        404: {"description": "Không tìm thấy lớp"},
        409: {"description": "Không thể xóa do ràng buộc"},
        500: {"description": "Lỗi máy chủ"}
    }
)
async def delete_lop(
    malop: str,
    user=Depends(require_pgv)
):
    """
    Xóa lớp theo mã.

    Parameters:
    - **malop**: Mã lớp cần xóa

    Quyền: PGV
    """
    try:
        service.delete_lop(user, malop)
        return {"message": "Xóa thành công"}
    except Exception as e:
        logger.error(f"Error in delete_lop: {e}")
        if hasattr(e, 'status_code'):
            # If it's an HTTPException from the service, pass it through
            raise
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Lỗi hệ thống khi xóa lớp"
        )
