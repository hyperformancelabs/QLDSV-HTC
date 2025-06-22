"""API router configuration."""

from fastapi import APIRouter

from app.api.endpoints import health, auth

# Create the main API router without prefix (prefix is added in application.py)
api_router = APIRouter()

# Include all endpoint routers
api_router.include_router(health.router, prefix="/system", tags=["Health"])

# Authentication router
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])

# Add more routers here as needed
# api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
# api_router.include_router(users.router, prefix="/users", tags=["Users"])
