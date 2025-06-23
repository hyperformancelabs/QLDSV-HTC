"""Pydantic models for LOP (class) data validation."""

from __future__ import annotations

from pydantic import BaseModel, constr, Field, field_validator, ConfigDict


class LopBase(BaseModel):
    """Base model for LOP (class) entity."""

    malop: constr(strip_whitespace=True, min_length=1,
                  max_length=10) = Field(
        ...,
        alias="MALOP",
        description="Mã lớp, độ dài tối đa 10 ký tự",
        example="CNTT2021"
    )
    tenlop: constr(strip_whitespace=True, min_length=1,
                   max_length=50) = Field(
        ...,
        alias="TENLOP",
        description="Tên lớp, độ dài tối đa 50 ký tự",
        example="Công nghệ thông tin K46"
    )
    khoahoc: constr(strip_whitespace=True, min_length=1,
                    max_length=9) = Field(
        ...,
        alias="KHOAHOC",
        description="Khóa học (năm bắt đầu - năm kết thúc)",
        example="2021-2025"
    )
    makhoa: constr(strip_whitespace=True, min_length=1,
                   max_length=10) = Field(
        ...,
        alias="MAKHOA",
        description="Mã khoa quản lý lớp",
        example="CNTT"
    )

    # Configure model settings
    model_config = {
        "populate_by_name": True,
        "from_attributes": True,
        "json_schema_extra": {
            "example": {
                "MALOP": "CNTT2021",
                "TENLOP": "Công nghệ thông tin K46",
                "KHOAHOC": "2021-2025",
                "MAKHOA": "CNTT"
            }
        }
    }

    @field_validator('malop', 'tenlop', 'khoahoc', 'makhoa')
    @classmethod
    def validate_not_empty(cls, v: str) -> str:
        """Validate that string fields are not empty after stripping."""
        if not v or not v.strip():
            raise ValueError("Giá trị không được để trống")
        return v


class LopCreateUpdate(LopBase):
    """Request model for creating or updating a class."""
    pass


class LopWithStudentCount(LopBase):
    """Class with student count information."""
    tenkhoa: str = Field(
        "",
        alias="TENKHOA",
        description="Tên khoa quản lý",
        example="Công nghệ thông tin"
    )
    sosinhvien: int = Field(
        0,
        alias="SOSINHVIEN",
        description="Số lượng sinh viên trong lớp",
        example=30
    )


class LopResponse(LopBase):
    """Response model for class data."""
    pass


class LopListResponse(BaseModel):
    """Response model for a list of classes."""
    data: list[LopWithStudentCount] = Field(
        ...,
        description="Danh sách các lớp"
    )

    # Additional configuration for response with nested models
    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class LopFilters(BaseModel):
    """Filters for class list."""
    makhoa: str | None = Field(
        None,
        description="Lọc theo mã khoa",
        example="CNTT"
    )
    khoahoc: str | None = Field(
        None,
        description="Lọc theo khóa học",
        example="2021-2025"
    )


class LopInfoResponse(LopBase):
    """Response model for class with student count."""
    soluongsv: int = Field(
        0,
        alias="SOLUONGSV",
        description="Số lượng sinh viên trong lớp",
        example=30
    )
