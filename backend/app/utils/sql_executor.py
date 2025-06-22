from __future__ import annotations

"""High-level SQL execution utilities.

This helper is primarily intended for **setup / maintenance scripts**—it is
*not* used by request-time service code (which should rely on stored
procedures and the repository layer).  Features:

• Variable substitution ``$(VAR)`` using ``APP_SETTINGS`` or custom mapping.
• Respect the ``GO`` batch separator (which pyodbc does not understand).
• Convenience API: execute one query, many batches, or an entire ``.sql`` file.
• Re-uses :pyfunc:`app.db.connection.build_connection_string` so there is a
  single source of truth for building connection strings.
"""

import logging
import re
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Union

import pyodbc

from app.core.config import APP_SETTINGS
from app.db.connection import build_connection_string

logger = logging.getLogger("app.utils.sql_executor")
pyodbc.pooling = True  # keep pooling on


class SQLExecutor:  # noqa: WPS110 – utility class, not a data model
    """Utility for executing raw SQL text via *pyodbc*."""

    _GO_REGEX = re.compile(r"^\s*GO\s*$", flags=re.IGNORECASE | re.MULTILINE)
    _VAR_REGEX = re.compile(r"\$\((?P<name>[A-Za-z_][A-Za-z0-9_]*)\)")

    def __init__(
        self,
        *,
        user: Optional[str] = None,
        password: Optional[str] = None,
        default_database: Optional[str] = None,
        autocommit: bool = True,
    ) -> None:
        self.user = user or APP_SETTINGS.MSSQL_APP_USER
        self.password = password or APP_SETTINGS.MSSQL_APP_PASSWORD
        self.default_database = default_database or APP_SETTINGS.DB_NAME
        self.autocommit = autocommit

        logger.debug(
            "SQLExecutor → user=%s, db=%s, autocommit=%s",
            self.user,
            self.default_database,
            self.autocommit,
        )

    # ------------------------------------------------------------------
    # Public helpers
    # ------------------------------------------------------------------
    def execute_query(
        self,
        query: str,
        params: Union[Sequence, Dict[str, object], None] = None,
        *,
        database: Optional[str] = None,
    ) -> List[pyodbc.Row]:
        """Run a single SQL statement and return *all* rows (if any)."""
        with self._connect(database) as conn:
            cur = conn.cursor()
            cur.execute(query, params or ())
            try:
                return cur.fetchall()
            except pyodbc.ProgrammingError:
                return []

    def execute_batches(
        self,
        sql_text: str,
        *,
        variables: Optional[Dict[str, str]] = None,
        database: Optional[str] = None,
    ) -> None:
        """Execute multi-batch SQL *text* (honours ``GO`` separators)."""
        preprocessed = self._preprocess(sql_text, variables)
        for batch in self._split_batches(preprocessed):
            if batch.strip():
                logger.debug("Executing batch with %d characters", len(batch))
                self.execute_query(batch, database=database)

    def execute_file(
        self,
        file_path: Union[str, Path],
        *,
        variables: Optional[Dict[str, str]] = None,
        database: Optional[str] = None,
        encoding: str = "utf-8",
    ) -> None:
        """Read and execute a ``.sql`` file on the server."""
        sql_text = Path(file_path).read_text(encoding=encoding)
        self.execute_batches(sql_text, variables=variables, database=database)

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------
    def _connect(self, database: Optional[str] = None) -> pyodbc.Connection:  # noqa: WPS111
        db = database or self.default_database
        conn_str = build_connection_string(self.user, self.password, db)
        safe_str = conn_str.split("PWD=")[0] + "PWD=******"
        logger.debug("Opening connection with: %s", safe_str)
        return pyodbc.connect(conn_str, autocommit=self.autocommit)

    # Text utilities ----------------------------------------------------
    @classmethod
    def _split_batches(cls, sql_text: str) -> List[str]:
        parts: List[str] = []
        last = 0
        for match in cls._GO_REGEX.finditer(sql_text):
            start, end = match.span()
            parts.append(sql_text[last:start])
            last = end
        parts.append(sql_text[last:])
        return parts

    @classmethod
    def _substitute_variables(cls, sql_text: str, mapping: Dict[str, str]) -> str:
        def _repl(match: re.Match[str]) -> str:
            name = match.group("name")
            return mapping.get(name, match.group(0))

        return cls._VAR_REGEX.sub(_repl, sql_text)

    def _preprocess(self, sql_text: str, variables: Optional[Dict[str, str]]) -> str:
        env_map = {k: str(v) for k, v in APP_SETTINGS.as_dict().items()}
        merged = {**env_map, **(variables or {})}
        return self._substitute_variables(sql_text, merged)
