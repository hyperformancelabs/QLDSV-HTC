"""Authentication endpoints."""

from __future__ import annotations

import logging
from typing import Dict, Any

from fastapi import APIRouter, Depends, Request, Response, status, HTTPException
from fastapi.responses import JSONResponse

from app.schemas.auth import LoginRequest, UserInfo
from app.services.auth import AuthService
from app.api.dependencies.auth import get_current_user, SESSION_KEY

router = APIRouter()
logger = logging.getLogger("app.api.auth")

auth_service = AuthService()


@router.post(
    "/login",
    response_model=UserInfo,
    summary="Đăng nhập",
    description="Đăng nhập và lưu thông tin người dùng vào session",
    responses={
        200: {"description": "Đăng nhập thành công"},
        401: {"description": "Đăng nhập thất bại"}
    }
)
async def login(request: Request, payload: LoginRequest):
    """Authenticate user and persist data in session cookie."""
    logger.debug(f"Login attempt for username '{payload.username}'")
    try:
        # Use auth service to validate credentials
        user_info = auth_service.login(payload.username, payload.password)

        # Save to session if login successful
        request.session[SESSION_KEY] = user_info
        logger.info(
            f"User '{user_info['username']}' logged in with role '{user_info['role']}'")

        return user_info
    except Exception as e:
        logger.warning(f"Login failed for '{payload.username}': {str(e)}")
        if hasattr(e, 'status_code'):
            # Re-raise HTTP exceptions from the service
            raise
        # For other exceptions, return 401 Unauthorized
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Đăng nhập thất bại"
        )


@router.post(
    "/logout",
    summary="Đăng xuất",
    description="Xóa thông tin người dùng khỏi session",
    responses={
        200: {"description": "Đăng xuất thành công"}
    }
)
async def logout(request: Request):
    """Clear user session data."""
    # Log the logout event if user was logged in
    user = request.session.get(SESSION_KEY)
    if user:
        logger.info(f"User '{user.get('username')}' logged out")

    # Remove the session data
    request.session.pop(SESSION_KEY, None)

    return JSONResponse({"message": "Đăng xuất thành công"})


@router.get(
    "/me",
    response_model=UserInfo,
    summary="Thông tin người dùng hiện tại",
    description="Lấy thông tin người dùng đã đăng nhập",
    responses={
        200: {"description": "Thông tin người dùng"},
        401: {"description": "Chưa đăng nhập"}
    }
)
async def get_me(user: Dict[str, Any] = Depends(get_current_user)):
    """Return current logged in user info."""
    return user
