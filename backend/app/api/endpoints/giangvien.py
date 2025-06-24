"""Endpoints for lecturer and lecturer account management."""

from __future__ import annotations

from typing import List, Optional

from fastapi import APIRouter, Depends, Query, Path, status, Response

from app.api.dependencies.auth import require_pgv, require_pgv_or_khoa, get_current_user
from app.schemas.giangvien import (
    GiangVienWithLoginStatus, CreateGiangVienRequest, UpdateGiangVienRequest,
    CreateLoginRequest, UpdatePasswordRequest, ToggleLoginRequest
)
from app.services.giangvien import GiangVienService

router = APIRouter()
service = GiangVienService()

# ====================================================================
# Lecturer Info CRUD
# ====================================================================


@router.get(
    "",
    response_model=List[GiangVienWithLoginStatus],
    summary="Search, filter, and list lecturers",
    dependencies=[Depends(require_pgv_or_khoa)],
)
async def list_lecturers(
    search: Optional[str] = Query(None, description="Search by name or MAGV"),
    makhoa: Optional[str] = Query(None, description="Filter by department ID"),
    hocvi: Optional[str] = Query(None, description="Filter by degree"),
    has_login: Optional[bool] = Query(
        None, description="Filter by login status"),
    user=Depends(get_current_user),
):
    """
    Get a list of lecturers with advanced filtering.
    - **PGV** can see all lecturers.
    - **KHOA** can only see lecturers in their own department.
    """
    return service.get_all(user, search, makhoa, hocvi, has_login)


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    response_model=GiangVienWithLoginStatus,
    dependencies=[Depends(require_pgv)],
    summary="Create a new lecturer",
)
async def create_lecturer(
    payload: CreateGiangVienRequest,
    user=Depends(get_current_user),
):
    """Create a new lecturer record. Requires PGV role."""
    return service.create(user, payload)


@router.get(
    "/{magv}",
    response_model=GiangVienWithLoginStatus,
    dependencies=[Depends(require_pgv_or_khoa)],
    summary="Get lecturer by ID",
)
async def get_lecturer_by_id(
    magv: str = Path(..., description="Lecturer ID"),
    user=Depends(get_current_user),
):
    """Get a single lecturer by their MAGV."""
    return service.get_by_id(user, magv)


@router.put(
    "/{magv}",
    response_model=GiangVienWithLoginStatus,
    dependencies=[Depends(require_pgv)],
    summary="Update lecturer information",
)
async def update_lecturer(
    payload: UpdateGiangVienRequest,
    magv: str = Path(..., description="Lecturer ID to update"),
    user=Depends(get_current_user),
):
    """Update a lecturer's information. Requires PGV role."""
    return service.update(user, magv, payload)


@router.delete(
    "/{magv}",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[Depends(require_pgv)],
    summary="Delete a lecturer",
)
async def delete_lecturer(
    magv: str = Path(..., description="Lecturer ID to delete"),
    user=Depends(get_current_user),
):
    """
    Delete a lecturer record. Fails if the lecturer has an active login account.
    Requires PGV role.
    """
    service.delete(user, magv)
    return Response(status_code=status.HTTP_204_NO_CONTENT)

# ====================================================================
# Lecturer Account Management
# ====================================================================


@router.post(
    "/{magv}/account",
    status_code=status.HTTP_201_CREATED,
    response_model=GiangVienWithLoginStatus,
    dependencies=[Depends(require_pgv)],
    summary="Create a login account for a lecturer",
)
async def create_lecturer_login(
    payload: CreateLoginRequest,
    magv: str = Path(..., description="Lecturer ID to create account for"),
    user=Depends(get_current_user),
):
    """Create a SQL Server login and DB user for an existing lecturer. Requires PGV role."""
    return service.create_login(user, magv, payload)


@router.delete(
    "/{magv}/account",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[Depends(require_pgv)],
    summary="Delete a lecturer's login account",
)
async def delete_lecturer_login(
    magv: str = Path(...,
                     description="Lecturer ID whose account will be deleted"),
    user=Depends(get_current_user),
):
    """Delete a lecturer's SQL Server login and DB user. Requires PGV role."""
    service.delete_login(user, magv)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.patch(
    "/{magv}/account/password",
    response_model=GiangVienWithLoginStatus,
    dependencies=[Depends(require_pgv)],
    summary="Update a lecturer's password",
)
async def update_lecturer_password(
    payload: UpdatePasswordRequest,
    magv: str = Path(...,
                     description="Lecturer ID whose password will be updated"),
    user=Depends(get_current_user),
):
    """Update a lecturer's login password. Requires PGV role."""
    return service.update_password(user, magv, payload)


@router.patch(
    "/{magv}/account/toggle",
    response_model=GiangVienWithLoginStatus,
    dependencies=[Depends(require_pgv)],
    summary="Disable or enable a lecturer's account",
)
async def toggle_lecturer_login(
    payload: ToggleLoginRequest,
    magv: str = Path(...,
                     description="Lecturer ID whose account will be toggled"),
    user=Depends(get_current_user),
):
    """Disable or enable a lecturer's login account. Requires PGV role."""
    return service.toggle_login(user, magv, payload)
