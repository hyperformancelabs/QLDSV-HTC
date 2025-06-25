"""Authentication-related dependencies."""

from __future__ import annotations

import logging
from typing import Dict, Any, Optional, List

from fastapi import Request, HTTPException, status

logger = logging.getLogger("app.api.dependencies.auth")

SESSION_KEY = "user"  # key in session dictionary


def get_current_user(request: Request) -> Dict[str, Any]:
    """
    Get the current authenticated user from the session.

    Args:
        request: The FastAPI request object with session

    Returns:
        Dict containing user information

    Raises:
        HTTPException: If no user is logged in (401 Unauthorized)
    """
    user = request.session.get(SESSION_KEY)
    if not user:
        logger.warning("Unauthorized access attempt - no active session")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Chưa đăng nhập hoặc phiên đã hết hạn"
        )
    return user.copy()


def get_optional_user(request: Request) -> Optional[Dict[str, Any]]:
    """
    Get the current user if logged in, or None if not logged in.

    Args:
        request: The FastAPI request object with session

    Returns:
        Dict containing user information or None
    """
    session_user = request.session.get(SESSION_KEY)
    return session_user.copy() if session_user else None


def require_role(required_roles: list[str]):
    """
    Factory function to create a dependency that checks for specific roles.

    Args:
        required_roles: List of allowed role names

    Returns:
        A dependency function that checks the user's role
    """
    def dependency(request: Request) -> Dict[str, Any]:
        # First check if user is logged in
        user = get_current_user(request)

        # Then check if user's role is in the allowed roles list
        if user.get("role") not in required_roles:
            logger.warning(
                f"Permission denied: User with role '{user.get('role')}' "
                f"attempted to access resource requiring {required_roles}"
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Bạn không có quyền truy cập chức năng này"
            )

        return user

    return dependency


def check_role_permission(user: Dict[str, Any], allowed_roles: List[str]) -> None:
    """
    Check if a user has one of the allowed roles.

    Args:
        user: User dictionary from session
        allowed_roles: List of role names that are allowed

    Raises:
        HTTPException: If the user doesn't have any of the required roles
    """
    user_roles = user.get("roles", [])

    # Check if any of the user's roles match the allowed roles
    if not any(role in allowed_roles for role in user_roles):
        logger.warning(
            f"Permission denied: User with roles {user_roles} "
            f"attempted to access resource requiring one of {allowed_roles}"
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bạn không có quyền truy cập chức năng này"
        )


# Predefined role-based dependencies
require_pgv = require_role(["pgv_role"])
require_khoa = require_role(["khoa_role"])
require_pgv_or_khoa = require_role(["pgv_role", "khoa_role"])
require_sv = require_role(["sv_role"])
