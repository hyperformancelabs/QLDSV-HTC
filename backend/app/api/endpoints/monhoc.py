"""Endpoints for MONHOC (subject) management."""

from __future__ import annotations

import logging
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.responses import JSONResponse

from app.schemas.monhoc import (
    MonHocResponse,
    MonHocListResponse,
    MonHocCreateUpdate,
)
from app.services.monhoc import MonHocService
from app.api.dependencies.auth import get_current_user, require_pgv, require_pgv_or_khoa

router = APIRouter()
logger = logging.getLogger("app.api.monhoc")

service = MonHocService()


@router.get(
    "/",
    response_model=MonHocListResponse,
    summary="Danh sách môn học",
    description="Lấy danh sách môn học với bộ lọc tùy chọn. PGV và KHOA có quyền xem.",
    responses={
        200: {"description": "Danh sách môn học"},
        401: {"description": "Chưa đăng nhập"},
        403: {"description": "Không có quyền truy cập"},
        500: {"description": "Lỗi máy chủ"}
    }
)
async def list_monhoc(
    mamh: Optional[str] = None,
    tenmh: Optional[str] = None,
    user=Depends(require_pgv_or_khoa)
):
    """
    Lấy danh sách môn học với bộ lọc tùy chọn.

    Parameters:
    - **mamh**: Mã môn học (tìm chính xác)
    - **tenmh**: Tên môn học (tìm kiếm LIKE)

    Quyền: PGV, KHOA
    """
    try:
        data = service.list_monhoc(user, mamh, tenmh)
        return {"data": data}
    except Exception as e:
        logger.error(f"Error in list_monhoc: {e}")
        if hasattr(e, 'status_code'):
            # If it's an HTTPException from the service, pass it through
            raise
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Lỗi khi lấy danh sách môn học"
        )


@router.post(
    "/",
    status_code=status.HTTP_201_CREATED,
    summary="Thêm/Cập nhật môn học",
    description="Thêm mới hoặc cập nhật môn học nếu đã tồn tại. Chỉ PGV có quyền.",
    responses={
        201: {"description": "Thêm/cập nhật thành công"},
        400: {"description": "Dữ liệu không hợp lệ"},
        401: {"description": "Chưa đăng nhập"},
        403: {"description": "Không có quyền"},
        500: {"description": "Lỗi máy chủ"}
    }
)
async def upsert_monhoc(
    payload: MonHocCreateUpdate,
    user=Depends(require_pgv)
):
    """
    Thêm mới hoặc cập nhật môn học.

    Parameters:
    - **MAMH**: Mã môn học (khóa chính)
    - **TENMH**: Tên môn học (phải duy nhất)
    - **SOTIET_LT**: Số tiết lý thuyết (>= 0)
    - **SOTIET_TH**: Số tiết thực hành (>= 0)

    Quyền: PGV
    """
    try:
        service.upsert_monhoc(
            user,
            payload.mamh,
            payload.tenmh,
            payload.sotiet_lt,
            payload.sotiet_th,
        )
        return JSONResponse(
            {"message": "Ghi thành công"},
            status_code=status.HTTP_201_CREATED
        )
    except Exception as e:
        logger.error(f"Error in upsert_monhoc: {e}")
        if hasattr(e, 'status_code'):
            # If it's an HTTPException from the service, pass it through
            raise
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Lỗi hệ thống khi lưu môn học"
        )


@router.delete(
    "/{mamh}",
    summary="Xóa môn học",
    description="Xóa môn học theo mã. Chỉ thành công nếu môn học chưa liên kết với lớp tín chỉ. Chỉ PGV có quyền.",
    responses={
        200: {"description": "Xóa thành công"},
        400: {"description": "Dữ liệu không hợp lệ"},
        401: {"description": "Chưa đăng nhập"},
        403: {"description": "Không có quyền"},
        404: {"description": "Không tìm thấy môn học"},
        409: {"description": "Không thể xóa do ràng buộc"},
        500: {"description": "Lỗi máy chủ"}
    }
)
async def delete_monhoc(
    mamh: str,
    user=Depends(require_pgv)
):
    """
    Xóa môn học theo mã.

    Parameters:
    - **mamh**: Mã môn học cần xóa

    Quyền: PGV
    """
    try:
        service.delete_monhoc(user, mamh)
        return {"message": "Xóa thành công"}
    except Exception as e:
        logger.error(f"Error in delete_monhoc: {e}")
        if hasattr(e, 'status_code'):
            # If it's an HTTPException from the service, pass it through
            raise
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Lỗi hệ thống khi xóa môn học"
        )
