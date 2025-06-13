"""
Authentication schemas for QLDSV-HTC

This module provides Pydantic models for authentication requests and responses.
"""

from typing import List, Optional
from pydantic import BaseModel, Field


class StudentLoginRequest(BaseModel):
    """Student login request model"""
    masv: Optional[str] = Field(None, description="Student ID")
    ho_ten: Optional[str] = Field(None, description="Student full name")
    password: str = Field(..., description="Student password")


class StudentBase(BaseModel):
    """Base student information model"""
    masv: str = Field(..., description="Student ID")
    ho: str = Field(..., description="Student last name")
    ten: str = Field(..., description="Student first name")
    malop: str = Field(..., description="Student class ID")


class StudentSearchResult(BaseModel):
    """Student search result model for dropdown selection (minimal info)"""
    masv: str = Field(..., description="Student ID")
    ho: str = Field(..., description="Student last name")
    ten: str = Field(..., description="Student first name")
    display_name: str = Field(..., description="Display name for dropdown")


class StudentResponse(StudentBase):
    """Student response model with full information"""
    phai: bool = Field(...,
                       description="Student gender (False: Male, True: Female)")
    ngaysinh: Optional[str] = Field(None, description="Student birth date")
    diachi: Optional[str] = Field(None, description="Student address")
    danghihoc: bool = Field(...,
                            description="Student status (False: Active, True: Inactive)")
    role: str = Field("SV", description="User role (always SV for students)")


class StudentListItem(StudentBase):
    """Student list item model for dropdown selection"""
    display_name: str = Field(..., description="Display name for dropdown")


class StudentListResponse(BaseModel):
    """Student list response model"""
    students: List[StudentListItem] = Field(...,
                                            description="List of students")


class LoginResponse(BaseModel):
    """Login response model"""
    success: bool = Field(..., description="Login success status")
    message: str = Field(..., description="Login message")
    student: Optional[StudentResponse] = Field(
        None, description="Student information if login successful")


class TeacherLoginRequest(BaseModel):
    """Teacher login request model"""
    magv: Optional[str] = Field(None, description="Teacher ID")
    ho_ten: Optional[str] = Field(None, description="Teacher full name")
    password: str = Field(..., description="SQL Server login password")


class TeacherBase(BaseModel):
    """Base teacher information model"""
    magv: str = Field(..., description="Teacher ID")
    ho: str = Field(..., description="Teacher last name")
    ten: str = Field(..., description="Teacher first name")
    makhoa: str = Field(..., description="Teacher department ID")


class TeacherSearchResult(BaseModel):
    """Teacher search result model for dropdown selection (minimal info)"""
    magv: str = Field(..., description="Teacher ID")
    ho: str = Field(..., description="Teacher last name")
    ten: str = Field(..., description="Teacher first name")
    display_name: str = Field(..., description="Display name for dropdown")


class TeacherResponse(TeacherBase):
    """Teacher response model with full information"""
    hocvi: Optional[str] = Field(None, description="Teacher degree")
    hocham: Optional[str] = Field(None, description="Teacher title")
    chuyenmon: Optional[str] = Field(
        None, description="Teacher specialization")
    role: str = Field(..., description="User role (PGV or KHOA)")


class TeacherListItem(TeacherBase):
    """Teacher list item model for dropdown selection"""
    display_name: str = Field(..., description="Display name for dropdown")


class TeacherListResponse(BaseModel):
    """Teacher list response model"""
    teachers: List[TeacherListItem] = Field(...,
                                            description="List of teachers")
