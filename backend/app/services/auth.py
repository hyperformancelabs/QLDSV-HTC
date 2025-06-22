"""Business logic for authentication services."""

from __future__ import annotations

import logging
from typing import Dict

from fastapi import HTTPException, status

from app.db.repositories.auth import AuthRepository

logger = logging.getLogger("app.services.auth")


class AuthService:
    """Provide high level authentication operations."""

    def __init__(self) -> None:
        self.repo = AuthRepository()

    def login(self, username: str, password: str) -> Dict[str, str]:
        """Login user either as teacher (PGV/KHOA) or student.

        The resolution strategy is:
            1. Attempt teacher login by using the provided credentials as SQL
               Server login.  If successful, returns teacher user_info.
            2. If connection fails, fallback to student login which authenticates
               against SINHVIEN table via shared SV credentials.
        """
        # Attempt teacher login first.  Teacher login uses SQL credentials that
        # can open a connection directly.
        try:
            logger.debug("Trying teacher login for '%s'", username)
            return self.repo.login_teacher(username, password)
        except Exception as teacher_err:
            logger.debug(
                "Teacher login failed for '%s' (%s). Trying student login...",
                username,
                str(teacher_err),
            )
            # Continue to student login path.

        # Fallback to student login
        try:
            logger.debug("Trying student login for '%s'", username)
            return self.repo.login_student(username, password)
        except Exception as student_err:
            logger.warning(
                "Student login failed for '%s': %s", username, str(student_err)
            )
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Tên đăng nhập hoặc mật khẩu không hợp lệ",
            ) from student_err
