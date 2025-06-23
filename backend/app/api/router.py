"""API router configuration."""

from fastapi import APIRouter

from app.api.endpoints import health, auth, monhoc

# Create the main API router without prefix (prefix is added in application.py)
api_router = APIRouter()

# Include system health endpoint
api_router.include_router(health.router, prefix="/system", tags=["Health"])

# Authentication router
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])

# MONHOC management router
api_router.include_router(monhoc.router, prefix="/monhoc", tags=["MonHoc"])

# Add more routers here as needed
# Example:
# api_router.include_router(users.router, prefix="/users", tags=["Users"])
