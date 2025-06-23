"""Repository functions for SINHVIEN (student) entity."""

from __future__ import annotations

import logging
from typing import List, Dict, Optional, Tuple
from datetime import date

import pyodbc

from app.db.connection import get_connection_with_credentials

logger = logging.getLogger("app.db.repositories.sinhvien")


class SinhVienRepository:
    """Handle database operations for SINHVIEN entity through stored procedures."""

    def __init__(self, user: Dict[str, str]):
        """
        Initialize the repository with a database connection.

        Args:
            user: The authenticated user dictionary from the session.
                  It must contain 'username' and 'password' keys.
        """
        username = user.get("username")
        password = user.get("password")

        if not username or not password:
            raise ValueError(
                "User credentials (username, password) not found in session. Cannot connect to the database.")

        self.conn = get_connection_with_credentials(
            user=username, password=password)

    def _row_to_dict(self, row: pyodbc.Row) -> Dict[str, str | int | bool | date]:
        """
        Transform pyodbc row to a dictionary with consistent keys.

        Args:
            row: Database row from pyodbc

        Returns:
            Dictionary with standardized keys
        """
        # Handle both attribute access and index access (depending on cursor settings)
        result = {
            "MASV": row.MASV if hasattr(row, "MASV") else row[0],
            "HO": row.HO if hasattr(row, "HO") else row[1],
            "TEN": row.TEN if hasattr(row, "TEN") else row[2],
            "PHAI": row.PHAI if hasattr(row, "PHAI") else row[3],
            "NGAYSINH": row.NGAYSINH if hasattr(row, "NGAYSINH") else row[4],
            "DIACHI": row.DIACHI if hasattr(row, "DIACHI") else row[5],
            "DANGHIHOC": row.DANGHIHOC if hasattr(row, "DANGHIHOC") else row[6],
            "MALOP": row.MALOP if hasattr(row, "MALOP") else row[7],
        }

        # Optional field from V_SINHVIEN_INFO
        if hasattr(row, "TENLOP") or len(row) > 8:
            result["TENLOP"] = row.TENLOP if hasattr(row, "TENLOP") else row[8]

        return result

    def list_by_class(self,
                      malop: str,
                      page: int = 1,
                      page_size: int = 50,
                      search: Optional[str] = None,
                      sort_by: str = "HO",
                      sort_dir: str = "ASC") -> Tuple[List[Dict], int]:
        """
        Fetch paginated list of students by class.

        Args:
            malop: Class code filter
            page: Page number (1-based)
            page_size: Records per page
            search: Optional search term (MASV or name)
            sort_by: Column to sort by
            sort_dir: Sort direction ('ASC' or 'DESC')

        Returns:
            Tuple of (list of student dictionaries, total count)

        Raises:
            pyodbc.Error: On database errors
        """
        try:
            cursor = self.conn.cursor()

            # Execute stored procedure with parameters
            cursor.execute(
                "EXEC dbo.SP_SV_SelectByClass ?, ?, ?, ?, ?, ?",
                malop, page, page_size, search, sort_by, sort_dir
            )

            # Fetch student records
            rows = cursor.fetchall()
            students = [self._row_to_dict(row) for row in rows]

            # Get total count from second result set
            if cursor.nextset():
                count_row = cursor.fetchone()
                total_count = count_row[0] if count_row else 0
            else:
                total_count = len(students)  # Fallback

            return students, total_count

        except pyodbc.Error as err:
            logger.error(f"Error fetching student list: {err}")
            raise
        finally:
            # The connection is managed by the service layer or context
            pass

    def upsert(self,
               masv: str,
               ho: str,
               ten: str,
               malop: str,
               phai: bool,
               ngaysinh: date,
               diachi: str,
               danghihoc: bool = False,
               password: Optional[str] = None) -> None:
        """
        Create or update a student.

        Args:
            masv: Student code (primary key)
            ho: Last name
            ten: First name
            malop: Class code (foreign key)
            phai: Gender (False=Nam, True=Nữ)
            ngaysinh: Birth date
            diachi: Address
            danghihoc: Study status (False=active, True=inactive)
            password: Password (hashed at service layer)

        Raises:
            pyodbc.Error: On database errors, including constraint violations
        """
        try:
            cursor = self.conn.cursor()

            # Execute upsert stored procedure
            cursor.execute(
                "EXEC dbo.SP_SV_Upsert ?, ?, ?, ?, ?, ?, ?, ?, ?",
                masv, ho, ten, malop, phai, ngaysinh, diachi, danghihoc, password
            )

            # Commit the transaction
            self.conn.commit()
            logger.info(f"Successfully upserted student: {masv}")
        except pyodbc.Error as err:
            self.conn.rollback()
            logger.error(f"Error upserting student: {err}")
            raise
        finally:
            pass

    def delete(self, masv: str) -> None:
        """
        Delete a student by code.

        Args:
            masv: Student code to delete

        Raises:
            pyodbc.Error: If deletion fails
        """
        try:
            cursor = self.conn.cursor()

            # Execute delete stored procedure
            cursor.execute("EXEC dbo.SP_SV_Delete ?", masv)

            # Commit the transaction
            self.conn.commit()
            logger.info(f"Successfully deleted student: {masv}")
        except pyodbc.Error as err:
            self.conn.rollback()
            logger.error(f"Error deleting student {masv}: {err}")
            raise
        finally:
            pass

    def close_connection(self):
        """Close the database connection."""
        if self.conn:
            self.conn.close()
