"""Authentication endpoints."""

from __future__ import annotations

import logging
from typing import Dict, Any

from fastapi import APIRouter, Depends, Request, Response, status, HTTPException
from fastapi.responses import JSONResponse

from app.schemas.auth import LoginRequest, UserInfo
from app.services.auth import AuthService

router = APIRouter()
logger = logging.getLogger("app.api.auth")

auth_service = AuthService()

SESSION_KEY = "user"  # key in session dictionary


def get_current_user(request: Request) -> Dict[str, Any]:
    user = request.session.get(SESSION_KEY)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Chưa đăng nhập")
    return user


@router.post("/login", response_model=UserInfo, summary="Đăng nhập")
async def login(request: Request, payload: LoginRequest):
    """Authenticate user and persist data in session cookie."""
    logger.debug("Login attempt for username '%s'", payload.username)
    user_info = auth_service.login(payload.username, payload.password)

    # Save to session
    request.session[SESSION_KEY] = user_info
    logger.info("User '%s' logged in with role '%s'",
                user_info["username"], user_info["role"])

    return user_info


@router.post("/logout", summary="Đăng xuất")
async def logout(request: Request):
    user = request.session.get(SESSION_KEY)
    if user:
        logger.info("User '%s' logged out", user.get("username"))
    request.session.pop(SESSION_KEY, None)
    return JSONResponse({"message": "Đăng xuất thành công"})


@router.get("/me", response_model=UserInfo, summary="Thông tin người dùng hiện tại")
async def get_me(user: Dict[str, Any] = Depends(get_current_user)):
    return user
