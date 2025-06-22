"""Pydantic schemas for authentication endpoints."""

from __future__ import annotations

from pydantic import BaseModel, Field


class LoginRequest(BaseModel):
    username: str = Field(..., example="GV001_LOGIN")
    password: str = Field(..., example="123456")


class UserInfo(BaseModel):
    username: str
    fullname: str
    role: str
