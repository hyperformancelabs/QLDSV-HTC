"""
API router for QLDSV-HTC
"""

from fastapi import APIRouter
from app.api.endpoints import auth, health, student, system, teacher
from app.core.config import get_settings

# Get settings
settings = get_settings()

# Create main API router
api_router = APIRouter()

# Include all endpoint routers
api_router.include_router(health.router, tags=["health"])
api_router.include_router(system.router, tags=["system"])
api_router.include_router(student.router, prefix="/student", tags=["student"])
api_router.include_router(teacher.router, prefix="/teacher", tags=["teacher"])
api_router.include_router(
    auth.router, prefix=settings.AUTH_PREFIX, tags=["auth"])

# Add more endpoint routers as needed
# api_router.include_router(students.router, prefix="/students", tags=["students"])
# api_router.include_router(classes.router, prefix="/classes", tags=["classes"])
# api_router.include_router(courses.router, prefix="/courses", tags=["courses"])
# api_router.include_router(grades.router, prefix="/grades", tags=["grades"])
# api_router.include_router(users.router, prefix="/users", tags=["users"])
