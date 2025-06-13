"""
Teacher endpoints for QLDSV-HTC
"""

from fastapi import APIRouter, Depends, HTTPException, Request, Response, status
from pydantic import BaseModel
from typing import Dict, List, Optional
from app.services.auth_service import AuthService
from app.api.dependencies import get_current_user, pgv_only
from app.core.logger import setup_logger

# Setup logger
logger = setup_logger("api.teacher")

# Define request models


class TeacherCreationRequest(BaseModel):
    magv: str
    ho: str
    ten: str
    makhoa: str
    hocvi: Optional[str] = None
    hocham: Optional[str] = None
    chuyenmon: Optional[str] = None
    password: str
    role: Optional[str] = "KHOA"  # Default to KHOA role


# Create router
router = APIRouter()


@router.post("/create", dependencies=[Depends(pgv_only)])
async def create_teacher(creation_data: TeacherCreationRequest):
    """
    Create a new teacher (PGV only)
    """
    try:
        result = AuthService.register_teacher(
            magv=creation_data.magv,
            ho=creation_data.ho,
            ten=creation_data.ten,
            makhoa=creation_data.makhoa,
            hocvi=creation_data.hocvi,
            hocham=creation_data.hocham,
            chuyenmon=creation_data.chuyenmon,
            password=creation_data.password,
            role=creation_data.role
        )

        return result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error during teacher creation: {e}")
        raise HTTPException(
            status_code=500, detail=f"Teacher creation error: {str(e)}")


@router.get("/list")
async def get_teachers():
    """
    Get all teachers for dropdown selection
    """
    try:
        teachers = AuthService.get_all_teachers()
        return {"teachers": teachers}
    except Exception as e:
        logger.error(f"Error retrieving teachers: {e}")
        raise HTTPException(
            status_code=500, detail=f"Error retrieving teachers: {str(e)}")


@router.get("/{magv}")
async def get_teacher(magv: str):
    """
    Get teacher information by ID
    """
    try:
        return AuthService.get_teacher_by_id(magv)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving teacher: {e}")
        raise HTTPException(
            status_code=500, detail=f"Error retrieving teacher: {str(e)}")
