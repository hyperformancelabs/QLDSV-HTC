"""Pydantic models for SINHVIEN (student) data validation."""

from __future__ import annotations

from datetime import date
from typing import Optional

from pydantic import BaseModel, constr, Field, field_validator


class SinhVienBase(BaseModel):
    """Base model for SINHVIEN (student) entity."""

    masv: constr(strip_whitespace=True, min_length=1,
                 max_length=10) = Field(
        ...,
        alias="MASV",
        description="Mã sinh viên, độ dài tối đa 10 ký tự",
        example="N21DCCN001"
    )
    ho: constr(strip_whitespace=True, min_length=1,
               max_length=50) = Field(
        ...,
        alias="HO",
        description="Họ sinh viên, độ dài tối đa 50 ký tự",
        example="Nguyễn Văn"
    )
    ten: constr(strip_whitespace=True, min_length=1,
                max_length=10) = Field(
        ...,
        alias="TEN",
        description="Tên sinh viên, độ dài tối đa 10 ký tự",
        example="An"
    )
    malop: constr(strip_whitespace=True, min_length=1,
                  max_length=10) = Field(
        ...,
        alias="MALOP",
        description="Mã lớp sinh viên thuộc về",
        example="CNTT2021"
    )
    phai: bool = Field(
        ...,
        alias="PHAI",
        description="Phái (False=Nam, True=Nữ)",
        example=False
    )
    ngaysinh: date = Field(
        ...,
        alias="NGAYSINH",
        description="Ngày sinh",
        example="2003-01-15"
    )
    diachi: constr(strip_whitespace=True, min_length=1,
                   max_length=100) = Field(
        ...,
        alias="DIACHI",
        description="Địa chỉ sinh viên",
        example="Hà Nội"
    )
    danghihoc: bool = Field(
        False,
        alias="DANGHIHOC",
        description="Trạng thái nghỉ học (0: đang học, 1: nghỉ học)",
        example=False
    )

    # Configure model settings
    model_config = {
        "populate_by_name": True,
        "from_attributes": True,
        "json_schema_extra": {
            "example": {
                "MASV": "N21DCCN001",
                "HO": "Nguyễn Văn",
                "TEN": "An",
                "MALOP": "CNTT2021",
                "PHAI": False,
                "NGAYSINH": "2003-01-15",
                "DIACHI": "Hà Nội",
                "DANGHIHOC": False
            }
        }
    }

    @field_validator('masv', 'ho', 'ten', 'malop', 'diachi')
    @classmethod
    def validate_not_empty(cls, v: str) -> str:
        """Validate that string fields are not empty after stripping."""
        if not v or not v.strip():
            raise ValueError("Giá trị không được để trống")
        return v


class SinhVienCreate(SinhVienBase):
    """Request model for creating a student."""
    password: constr(strip_whitespace=True, min_length=6,
                     max_length=40) = Field(
        ...,
        alias="PASSWORD",
        description="Mật khẩu sinh viên",
        example="123456"
    )


class SinhVienUpdate(SinhVienBase):
    """Request model for updating a student."""
    password: Optional[constr(strip_whitespace=True, min_length=6,
                              max_length=40)] = Field(
        None,
        alias="PASSWORD",
        description="Mật khẩu sinh viên, NULL nếu không thay đổi",
        example="123456"
    )


class SinhVienResponse(SinhVienBase):
    """Response model for student data."""
    tenlop: Optional[str] = Field(
        None,
        alias="TENLOP",
        description="Tên lớp sinh viên thuộc về",
        example="Công nghệ thông tin K46"
    )

    # Override phai field to handle both string and boolean values
    phai: str = Field(
        ...,
        alias="PHAI",
        description="Phái (Nam/Nữ)",
        example="Nam"
    )

    @field_validator('phai', mode='before')
    @classmethod
    def convert_phai_to_string(cls, v):
        """Convert boolean PHAI values to strings."""
        if isinstance(v, bool):
            return "Nữ" if v else "Nam"
        return v


class SinhVienListResponse(BaseModel):
    """Response model for a list of students."""
    data: list[SinhVienResponse] = Field(
        ...,
        description="Danh sách sinh viên"
    )
    total: int = Field(
        ...,
        description="Tổng số sinh viên (cho phân trang)",
        example=150
    )
    page: int = Field(
        1,
        description="Trang hiện tại",
        example=1
    )
    page_size: int = Field(
        50,
        description="Số lượng bản ghi mỗi trang",
        example=50
    )
