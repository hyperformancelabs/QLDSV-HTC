"""
Authentication endpoints for QLDSV-HTC

This module provides API endpoints for authentication.
"""

from fastapi import APIRouter, Depends, HTTPException, Request, Response, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Dict, List, Optional
from app.schemas.auth import (
    StudentLoginRequest,
    StudentResponse,
    StudentListResponse,
    StudentListItem,
    LoginResponse,
    TeacherLoginRequest,
    TeacherResponse,
    TeacherListItem,
    TeacherListResponse,
    StudentSearchResult,
    TeacherSearchResult
)
from app.services.auth_service import AuthService
from app.api.dependencies import get_current_user, student_only, teacher_only
from app.core.logger import setup_logger
from app.core.config import get_settings

# Setup router
router = APIRouter()

# Setup logger
logger = setup_logger("api.auth")

# Get settings
settings = get_settings()

# Define request models


class LoginRequest(BaseModel):
    """
    Unified login request for both students and teachers
    Requires user_type to determine authentication method
    """
    id: str  # Either MASV or MAGV
    password: str
    user_type: str  # "student" or "teacher"


@router.post("/login")
async def login(
    request: Request,
    response: Response,
    login_data: LoginRequest
):
    """
    Authenticate user (student or teacher) with ID and password

    For students:
    - Uses MASV (student ID) and password stored in SINHVIEN table
    - Creates session with student information and role="SV"

    For teachers:
    - Uses MAGV (teacher ID) as SQL Server login name
    - Special cases for system users (pgv_user, khoa_user)
    - Creates session with teacher information and role="PGV" or "KHOA"

    Returns:
        JSON with status and user information on success
        HTTP 401 on authentication failure
    """
    try:
        if login_data.user_type == "student":
            # Student authentication
            user_info = AuthService.authenticate_student(
                masv=login_data.id,
                password=login_data.password
            )
        elif login_data.user_type == "teacher":
            # Teacher authentication
            user_info = AuthService.authenticate_teacher(
                magv=login_data.id,
                password=login_data.password
            )
        else:
            raise HTTPException(status_code=400, detail="Invalid user type")

        # Set session data
        AuthService.manage_session(request, response, user_info)

        return {"status": "success", "user": user_info}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Login error: {e}")
        raise HTTPException(status_code=500, detail=f"Login error: {str(e)}")


@router.post("/logout")
async def logout(request: Request, response: Response):
    """
    Logout current user and clear session
    """
    AuthService.manage_session(request, response, None)
    return {"status": "success", "message": "Logged out successfully"}


@router.get("/students")
async def get_students():
    """
    Get all students for dropdown selection
    """
    return AuthService.get_all_students()


@router.get("/students/search", response_model=List[StudentSearchResult])
async def search_students(search_term: str):
    """
    Search students by name or ID
    Returns minimal information for dropdown selection
    """
    return AuthService.search_students_by_name(search_term)


@router.get("/students/{masv}")
async def get_student(masv: str):
    """
    Get student information by ID
    """
    return AuthService.get_student_by_id(masv)


@router.get("/teachers")
async def get_teachers():
    """
    Get all teachers for dropdown selection
    """
    return AuthService.get_all_teachers()


@router.get("/teachers/search", response_model=List[TeacherSearchResult])
async def search_teachers(search_term: str):
    """
    Search teachers by name or ID
    Returns minimal information for dropdown selection
    """
    return AuthService.search_teachers_by_name(search_term)


@router.get("/teachers/{magv}")
async def get_teacher(magv: str):
    """
    Get teacher information by ID
    """
    return AuthService.get_teacher_by_id(magv)


@router.get("/me")
async def get_current_user_info(user: Dict = Depends(get_current_user)):
    """
    Get current authenticated user information
    """
    return user


@router.get("/protected-example", dependencies=[Depends(student_only)])
async def protected_student_route(user: Dict = Depends(get_current_user)):
    """
    Example of a protected route that only students can access
    """
    return {
        "status": "success",
        "message": f"Hello {user['ho']} {user['ten']}, you have access to this protected resource",
        "user_role": user["role"]
    }


@router.get("/protected-teacher-example", dependencies=[Depends(teacher_only)])
async def protected_teacher_route(user: Dict = Depends(get_current_user)):
    """
    Example of a protected route that only teachers can access
    """
    return {
        "status": "success",
        "message": f"Hello {user['ho']} {user['ten']}, you have access to this protected teacher resource",
        "user_role": user["role"]
    }
