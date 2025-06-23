"""Pydantic models for KHOA (faculty) data validation."""

from __future__ import annotations

from pydantic import BaseModel, constr, Field


class KhoaResponse(BaseModel):
    """Response model for faculty."""

    makhoa: constr(strip_whitespace=True, min_length=1, max_length=10) = Field(
        ..., alias="MAKHOA", description="Mã khoa", example="CNTT1"
    )
    tenkhoa: constr(strip_whitespace=True, min_length=1, max_length=50) = Field(
        ..., alias="TENKHOA", description="Tên khoa", example="Khoa Công nghệ thông tin 1"
    )

    model_config = {
        "populate_by_name": True,
        "from_attributes": True,
    }


class KhoaListResponse(BaseModel):
    """Response model for list of faculties."""

    data: list[KhoaResponse] = Field(..., description="Danh sách khoa")
