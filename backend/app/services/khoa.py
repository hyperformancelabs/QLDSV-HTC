"""Business logic for KHOA (faculty) operations."""

from __future__ import annotations

import logging
from typing import List, Dict

from fastapi import HTTPException, status

from app.db.repositories.khoa import KhoaRepository

logger = logging.getLogger("app.services.khoa")

ALLOWED_ROLES = ["pgv_role", "khoa_role"]


class KhoaService:  # noqa: WPS110 – service layer
    """Service layer for faculty operations."""

    def list_khoa(self, current_user: Dict[str, str]) -> List[Dict[str, str]]:
        """Return list of faculties for authorised users.

        Args:
            current_user: Authenticated user dict

        Returns:
            List of faculty dicts
        """
        if not current_user or current_user.get("role") not in ALLOWED_ROLES:
            logger.warning(
                "User with role %s attempted to list faculties", current_user.get(
                    "role", "none"),
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Bạn không có quyền xem danh sách khoa",
            )

        repo = None
        try:
            repo = KhoaRepository(current_user)
            return repo.list()
        except Exception as err:  # noqa: WPS429 – broad except to wrap
            logger.error("Error listing faculties: %s", err)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Lỗi khi lấy danh sách khoa",
            ) from err
        finally:
            if repo:
                repo.close_connection()
