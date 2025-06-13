"""
Student endpoints for QLDSV-HTC
"""

from fastapi import APIRouter, Depends, HTTPException, Request, Response, status
from pydantic import BaseModel
from typing import Dict, List, Optional
from app.services.auth_service import AuthService
from app.api.dependencies import get_current_user, student_only, pgv_only
from app.core.logger import setup_logger

# Setup logger
logger = setup_logger("api.student")

# Define request models


class StudentCreationRequest(BaseModel):
    masv: str
    ho: str
    ten: str
    malop: str
    phai: bool
    ngaysinh: str
    diachi: str
    password: str


# Create router
router = APIRouter()


@router.post("/create", dependencies=[Depends(pgv_only)])
async def create_student(creation_data: StudentCreationRequest):
    """
    Create a new student (PGV only)
    """
    try:
        result = AuthService.register_student(
            masv=creation_data.masv,
            ho=creation_data.ho,
            ten=creation_data.ten,
            malop=creation_data.malop,
            phai=creation_data.phai,
            ngaysinh=creation_data.ngaysinh,
            diachi=creation_data.diachi,
            password=creation_data.password
        )

        return result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error during student creation: {e}")
        raise HTTPException(
            status_code=500, detail=f"Student creation error: {str(e)}")
