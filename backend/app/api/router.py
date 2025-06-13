from fastapi import APIRouter
from app.api.endpoints import health, system

# Main API Router
api_router = APIRouter()

# Include all endpoint routers
api_router.include_router(health.router, tags=["health"])
api_router.include_router(system.router, tags=["system"])

# Add more endpoint routers as needed
# api_router.include_router(students.router, prefix="/students", tags=["students"])
# api_router.include_router(classes.router, prefix="/classes", tags=["classes"])
# api_router.include_router(courses.router, prefix="/courses", tags=["courses"])
# api_router.include_router(grades.router, prefix="/grades", tags=["grades"])
# api_router.include_router(users.router, prefix="/users", tags=["users"])
