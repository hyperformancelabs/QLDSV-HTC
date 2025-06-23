"""Endpoints for KHOA (faculty) management."""

from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, HTTPException, status

# we will create new schema but quick reuse; but better create KhoaResponse. We'll import pydantic. Let's implement quickly.
from app.schemas.khoa import KhoaListResponse
from app.services.khoa import KhoaService
from app.api.dependencies.auth import require_pgv_or_khoa

router = APIRouter()
logger = logging.getLogger("app.api.khoa")

service = KhoaService()


@router.get(
    "/",
    response_model=KhoaListResponse,
    summary="Danh sách khoa",
    description="Lấy danh sách khoa. PGV xem tất cả, KHOA xem được danh sách khoa (bao gồm khoa của mình).",
    responses={
        200: {"description": "Danh sách khoa"},
        401: {"description": "Chưa đăng nhập"},
        403: {"description": "Không có quyền truy cập"},
        500: {"description": "Lỗi máy chủ"},
    },
)
async def list_khoa(user=Depends(require_pgv_or_khoa)):
    """API endpoint to list faculties."""
    try:
        data = service.list_khoa(user)
        return {"data": data}
    except HTTPException:
        raise  # propagate expected
    except Exception as exc:  # noqa: WPS429 – broad to log
        logger.error("Error in list_khoa: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Lỗi khi lấy danh sách khoa",
        ) from exc
