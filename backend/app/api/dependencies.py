"""
API dependencies for QLDSV-HTC

This module provides dependency functions for FastAPI endpoints.
"""

from fastapi import Depends, HTTPException, Request, status
from typing import Dict, Optional, List, Callable, Any
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.core.config import get_settings
from app.core.logger import setup_logger

# Get settings
settings = get_settings()

# Setup logger
logger = setup_logger("api.dependencies")

# Security scheme for bearer token
security = HTTPBearer()


def get_current_user(request: Request) -> Dict:
    """
    Get the current authenticated user from session

    This function extracts user information from the session cookie.
    It is used as a dependency for protected endpoints that require authentication.
    The session contains user data and role information set during login.

    Args:
        request: FastAPI request object with session data

    Returns:
        Dict: User information including:
            - masv/magv: User ID
            - ho: Last name
            - ten: First name
            - role: User role (SV, PGV, KHOA)
            - Other user-specific fields

    Raises:
        HTTPException: 401 if user is not authenticated or session is invalid
    """
    if not request.session.get("authenticated"):
        logger.warning("Unauthenticated access attempt")
        raise HTTPException(status_code=401, detail="Not authenticated")

    user = request.session.get("user")
    if not user:
        logger.warning("Session exists but no user data found")
        raise HTTPException(status_code=401, detail="Invalid session")

    return user


def verify_role(required_roles: list[str]) -> Callable:
    """
    Create a dependency to verify user has one of the required roles

    This function creates a dependency that checks if the authenticated user
    has one of the specified roles. It is used to protect endpoints that
    require specific role-based permissions.

    Args:
        required_roles: List of roles allowed to access the endpoint
                       (e.g., ["SV"], ["PGV", "KHOA"])

    Returns:
        Callable: Dependency function that verifies user role

    Example:
        @router.get("/admin", dependencies=[Depends(verify_role(["ADMIN"]))])
        async def admin_route():
            return {"message": "Admin access granted"}
    """
    def role_checker(user: Dict = Depends(get_current_user)) -> Dict:
        """
        Check if user has one of the required roles

        Args:
            user: User information from session

        Returns:
            Dict: User information if role check passes

        Raises:
            HTTPException: 403 if user doesn't have required role
        """
        if user.get("role") not in required_roles:
            logger.warning(
                f"Role access denied: User has {user.get('role')}, required {required_roles}")
            raise HTTPException(
                status_code=403,
                detail=f"Access denied: Required role(s): {', '.join(required_roles)}"
            )
        return user

    return role_checker


# Role-specific dependencies
student_only = verify_role(["SV"])  # Only student access
pgv_only = verify_role(["PGV"])  # Only Phòng Giáo Vụ access
khoa_only = verify_role(["KHOA"])  # Only Khoa access
admin_only = verify_role(["ADMIN"])  # Only admin access
teacher_only = verify_role(["PGV", "KHOA"])  # Any teacher role (PGV or KHOA)

# Multi-role dependencies
staff_only = verify_role(["PGV", "KHOA", "ADMIN"])  # Any staff role
any_authenticated = verify_role(
    ["SV", "PGV", "KHOA", "ADMIN"])  # Any authenticated user
