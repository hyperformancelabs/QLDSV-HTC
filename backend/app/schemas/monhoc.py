"""Pydantic models for MONHOC (subject) data validation."""

from __future__ import annotations

from pydantic import BaseModel, constr, Field, field_validator


class MonHocBase(BaseModel):
    """Base model for MONHOC (subject) entity."""

    mamh: constr(strip_whitespace=True, min_length=1,
                 max_length=10) = Field(
        ...,
        alias="MAMH",
        description="Mã môn học, độ dài tối đa 10 ký tự",
        example="MMTT1005"
    )
    tenmh: constr(strip_whitespace=True, min_length=1,
                  max_length=50) = Field(
        ...,
        alias="TENMH",
        description="Tên môn học, độ dài tối đa 50 ký tự",
        example="Cơ sở dữ liệu phân tán"
    )
    sotiet_lt: int = Field(
        ...,
        ge=0,
        alias="SOTIET_LT",
        description="Số tiết lý thuyết, không âm",
        example=30
    )
    sotiet_th: int = Field(
        ...,
        ge=0,
        alias="SOTIET_TH",
        description="Số tiết thực hành, không âm",
        example=15
    )

    # Configure model settings
    model_config = {
        "populate_by_name": True,
        "from_attributes": True,
        "json_schema_extra": {
            "example": {
                "MAMH": "MMTT1005",
                "TENMH": "Cơ sở dữ liệu phân tán",
                "SOTIET_LT": 30,
                "SOTIET_TH": 15
            }
        }
    }

    @field_validator('mamh', 'tenmh')
    @classmethod
    def validate_not_empty(cls, v: str) -> str:
        """Validate that string fields are not empty after stripping."""
        if not v or not v.strip():
            raise ValueError("Giá trị không được để trống")
        return v

    @field_validator('sotiet_lt', 'sotiet_th')
    @classmethod
    def validate_not_negative(cls, v: int) -> int:
        """Validate that hour values are not negative."""
        if v < 0:
            raise ValueError("Số tiết không được âm")
        return v


class MonHocCreateUpdate(MonHocBase):
    """Request model for creating or updating a subject."""
    pass


class MonHocResponse(MonHocBase):
    """Response model for subject data with linked status."""
    is_linked: bool = Field(
        False,
        alias="IS_LINKED",
        description="Trạng thái liên kết với lớp tín chỉ",
        example=False
    )


class MonHocListResponse(BaseModel):
    """Response model for a list of subjects."""
    data: list[MonHocResponse] = Field(
        ...,
        description="Danh sách các môn học"
    )
