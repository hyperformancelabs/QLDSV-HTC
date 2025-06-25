"""Pydantic schemas for LOPTINCHI (class sections) and DANGKY (registrations)."""

from __future__ import annotations

from typing import Optional, List
from pydantic import BaseModel, Field, validator


class LopTinChiBase(BaseModel):
    """Base model for LOPTINCHI."""
    nienkhoa: str = Field(...,
                          description="Niên khóa (format: YYYY-YYYY)", alias="NIENKHOA")
    hocky: int = Field(..., description="Học kỳ (1-3)",
                       ge=1, le=3, alias="HOCKY")
    mamh: str = Field(..., description="Mã môn học", alias="MAMH")
    nhom: int = Field(..., description="Nhóm", ge=1, alias="NHOM")
    magv: str = Field(..., description="Mã giảng viên", alias="MAGV")
    makhoa: str = Field(..., description="Mã khoa quản lý", alias="MAKHOA")
    sosvtoithieu: int = Field(..., description="Số sinh viên tối thiểu",
                              gt=0, alias="SOSVTOITHIEU")

    class Config:
        """Pydantic config."""
        allow_population_by_field_name = True
        populate_by_name = True


class LopTinChiCreate(LopTinChiBase):
    """Schema for creating a new LOPTINCHI."""
    pass


class LopTinChiUpdate(LopTinChiBase):
    """Schema for updating an existing LOPTINCHI."""
    maltc: int = Field(..., description="Mã lớp tín chỉ", alias="MALTC")


class LopTinChiCancel(BaseModel):
    """Schema for canceling a LOPTINCHI."""
    maltc: int = Field(..., description="Mã lớp tín chỉ", alias="MALTC")

    class Config:
        allow_population_by_field_name = True
        populate_by_name = True


class LopTinChiRestore(BaseModel):
    """Schema for restoring a canceled LOPTINCHI."""
    maltc: int = Field(..., description="Mã lớp tín chỉ", alias="MALTC")

    class Config:
        allow_population_by_field_name = True
        populate_by_name = True


class LopTinChiFilter(BaseModel):
    """Schema for filtering LOPTINCHI."""
    nienkhoa: Optional[str] = Field(
        None, description="Niên khóa (format: YYYY-YYYY)", alias="NIENKHOA")
    hocky: Optional[int] = Field(
        None, description="Học kỳ (1-3)", ge=1, le=3, alias="HOCKY")
    makhoa: Optional[str] = Field(None, description="Mã khoa", alias="MAKHOA")
    only_available: Optional[bool] = Field(
        False, description="Chỉ lấy lớp chưa hủy")


class LopTinChiResponse(LopTinChiBase):
    """Schema for LOPTINCHI response with additional information."""
    maltc: int = Field(..., description="Mã lớp tín chỉ", alias="MALTC")
    tenmh: str = Field(..., description="Tên môn học", alias="TENMH")
    hotengv: str = Field(..., description="Họ tên giảng viên", alias="HOTENGV")
    tenkhoa: str = Field(..., description="Tên khoa", alias="TENKHOA")
    sosvdangky: int = Field(...,
                            description="Số sinh viên đã đăng ký", alias="SOSVDANGKY")
    huylop: bool = Field(..., description="Trạng thái hủy lớp", alias="HUYLOP")

    class Config:
        """Pydantic config."""
        orm_mode = True
        allow_population_by_field_name = True


class DangKyBase(BaseModel):
    """Base model for DANGKY."""
    maltc: int = Field(..., description="Mã lớp tín chỉ", alias="MALTC")
    masv: str = Field(..., description="Mã sinh viên", alias="MASV")


class DangKyCreate(DangKyBase):
    """Schema for creating a new DANGKY."""
    pass


class DangKyCancel(DangKyBase):
    """Schema for canceling a DANGKY."""
    pass


class DangKyResponse(BaseModel):
    """Schema for DANGKY response with additional information."""
    maltc: int = Field(..., description="Mã lớp tín chỉ", alias="MALTC")
    nienkhoa: str = Field(..., description="Niên khóa", alias="NIENKHOA")
    hocky: int = Field(..., description="Học kỳ", alias="HOCKY")
    tenmh: str = Field(..., description="Tên môn học", alias="TENMH")
    nhom: int = Field(..., description="Nhóm", alias="NHOM")
    hotengv: str = Field(..., description="Họ tên giảng viên", alias="HOTENGV")
    diem_cc: Optional[int] = Field(
        None, description="Điểm chuyên cần", alias="DIEM_CC")
    diem_gk: Optional[float] = Field(
        None, description="Điểm giữa kỳ", alias="DIEM_GK")
    diem_ck: Optional[float] = Field(
        None, description="Điểm cuối kỳ", alias="DIEM_CK")
    diem_het_mon: Optional[float] = Field(
        None, description="Điểm hết môn", alias="DIEM_HET_MON")
    huydangky: bool = Field(...,
                            description="Trạng thái hủy đăng ký", alias="HUYDANGKY")

    class Config:
        """Pydantic config."""
        orm_mode = True
        allow_population_by_field_name = True


class StudentInfo(BaseModel):
    """Schema for student information."""
    masv: str = Field(..., description="Mã sinh viên", alias="MASV")
    ho: str = Field(..., description="Họ", alias="HO")
    ten: str = Field(..., description="Tên", alias="TEN")
    malop: str = Field(..., description="Mã lớp", alias="MALOP")

    class Config:
        """Pydantic config."""
        orm_mode = True
        allow_population_by_field_name = True


class GradeFilters(BaseModel):
    """Schema for filtering students for grading."""
    nienkhoa: str = Field(...,
                          description="Niên khóa (format: YYYY-YYYY)", alias="NIENKHOA")
    hocky: int = Field(..., description="Học kỳ (1-3)",
                       ge=1, le=3, alias="HOCKY")
    mamh: str = Field(..., description="Mã môn học", alias="MAMH")
    nhom: int = Field(..., description="Nhóm", ge=1, alias="NHOM")

    class Config:
        """Pydantic config."""
        allow_population_by_field_name = True
        populate_by_name = True


class StudentGradeResponse(BaseModel):
    """Schema for student grade data."""
    masv: str = Field(..., description="Mã sinh viên", alias="MASV")
    ho: str = Field(..., description="Họ", alias="HO")
    ten: str = Field(..., description="Tên", alias="TEN")
    diem_cc: Optional[int] = Field(
        None, description="Điểm chuyên cần", alias="DIEM_CC", ge=0, le=10)
    diem_gk: Optional[float] = Field(
        None, description="Điểm giữa kỳ", alias="DIEM_GK", ge=0, le=10)
    diem_ck: Optional[float] = Field(
        None, description="Điểm cuối kỳ", alias="DIEM_CK", ge=0, le=10)
    diem_het_mon: Optional[float] = Field(
        None, description="Điểm hết môn", alias="DIEM_HET_MON")
    maltc: int = Field(..., description="Mã lớp tín chỉ", alias="MALTC")

    class Config:
        """Pydantic config."""
        orm_mode = True
        allow_population_by_field_name = True
        populate_by_name = True


class StudentGrade(BaseModel):
    """Schema for single student grade update."""
    masv: str = Field(..., description="Mã sinh viên", alias="MASV")
    maltc: int = Field(..., description="Mã lớp tín chỉ", alias="MALTC")
    diem_cc: Optional[int] = Field(
        None, description="Điểm chuyên cần", alias="DIEM_CC", ge=0, le=10)
    diem_gk: Optional[float] = Field(
        None, description="Điểm giữa kỳ", alias="DIEM_GK", ge=0, le=10)
    diem_ck: Optional[float] = Field(
        None, description="Điểm cuối kỳ", alias="DIEM_CK", ge=0, le=10)

    class Config:
        """Pydantic config."""
        allow_population_by_field_name = True
        populate_by_name = True


class MultipleGradesUpdate(BaseModel):
    """Schema for updating multiple student grades."""
    maltc: int = Field(..., description="Mã lớp tín chỉ", alias="MALTC")
    grades: List[StudentGrade] = Field(...,
                                       description="Danh sách điểm sinh viên")

    class Config:
        """Pydantic config."""
        allow_population_by_field_name = True
        populate_by_name = True
