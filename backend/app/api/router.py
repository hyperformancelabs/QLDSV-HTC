"""API router configuration."""

from fastapi import APIRouter

from app.api.endpoints import auth, health, monhoc, lop, sinhvien, khoa, giangvien

# Create the main API router without prefix (prefix is added in application.py)
api_router = APIRouter()

# Include system health endpoint
api_router.include_router(health.router, prefix="/health", tags=["Health"])

# Authentication router
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])

# MONHOC management router
api_router.include_router(monhoc.router, prefix="/monhoc", tags=["Mon Hoc"])

# LOP management router
api_router.include_router(lop.router, prefix="/lop", tags=["Lop"])

# SINHVIEN management router
api_router.include_router(
    sinhvien.router, prefix="/sinhvien", tags=["Sinh Vien"])

# KHOA management router
api_router.include_router(khoa.router, prefix="/khoa", tags=["Khoa"])

# GIANGVIEN management router
api_router.include_router(
    giangvien.router, prefix="/giangvien", tags=["Giang Vien"])

# Add more routers here as needed
# Example:
# api_router.include_router(users.router, prefix="/users", tags=["Users"])
