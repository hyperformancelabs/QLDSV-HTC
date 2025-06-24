"""Pydantic models for GiangVien API."""

from __future__ import annotations

from typing import Optional, List

from pydantic import BaseModel, Field, constr


# ====================================================================
# Base and Response Schemas
# ====================================================================

class GiangVienBase(BaseModel):
    ho: str = Field(..., max_length=50)
    ten: str = Field(..., max_length=10)
    hocvi: Optional[str] = Field(None, max_length=20)
    hocham: Optional[str] = Field(None, max_length=20)
    chuyenmon: Optional[str] = Field(None, max_length=50)
    makhoa: str = Field(..., max_length=10)


class GiangVien(GiangVienBase):
    magv: str = Field(..., max_length=10)

    model_config = {
        "populate_by_name": True,
        "from_attributes": True,
    }


class GiangVienWithLoginStatus(BaseModel):
    magv: str = Field(..., alias="MAGV")
    ho: str = Field(..., alias="HO")
    ten: str = Field(..., alias="TEN")
    hocvi: Optional[str] = Field(None, alias="HOCVI")
    hocham: Optional[str] = Field(None, alias="HOCHAM")
    chuyenmon: Optional[str] = Field(None, alias="CHUYENMON")
    makhoa: str = Field(..., alias="MAKHOA")
    tenkhoa: str = Field(..., alias="TENKHOA")
    has_login: bool = Field(..., alias="HasLogin")
    role_name: Optional[str] = Field(None, alias="RoleName")

    model_config = {
        "populate_by_name": True,
        "from_attributes": True,
    }

# ====================================================================
# Request Schemas for CRUD operations
# ====================================================================


class CreateGiangVienRequest(GiangVienBase):
    magv: constr(strip_whitespace=True, min_length=1, max_length=10)


class UpdateGiangVienRequest(GiangVienBase):
    pass


# ====================================================================
# Request Schemas for Account Management
# ====================================================================

class CreateLoginRequest(BaseModel):
    loginname: constr(strip_whitespace=True, min_length=3)
    password: constr(min_length=6)
    role: str = Field(..., pattern="^(pgv_role|khoa_role)$")


class UpdatePasswordRequest(BaseModel):
    new_password: constr(min_length=6)


class ToggleLoginRequest(BaseModel):
    is_disabled: bool

# ====================================================================
# Search Filters
# ====================================================================


class GiangVienSearchFilters(BaseModel):
    search: Optional[str] = None
    makhoa: Optional[str] = None
    hocvi: Optional[str] = None
    has_login: Optional[bool] = None
