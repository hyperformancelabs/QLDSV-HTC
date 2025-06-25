"""Repository functions for LOPTINCHI (class sections) and DANGKY (registrations)."""

from __future__ import annotations

import logging
from typing import List, Dict, Optional, Tuple, Union

import pyodbc

from app.db.connection import get_connection_with_credentials

logger = logging.getLogger("app.db.repositories.loptinchi")


class LopTinChiRepository:
    """Handle database operations for LOPTINCHI entity through stored procedures."""

    def __init__(self, user: Dict[str, str] = None, conn: pyodbc.Connection = None):
        """
        Initialize the repository with a database connection.

        Args:
            user: The authenticated user dictionary from the session.
                  It must contain 'username' and 'password' keys.
            conn: An existing database connection to use (alternative to user)

        Raises:
            ValueError: If neither user nor conn is provided
        """
        if conn:
            # Use the provided connection
            self.conn = conn
            self.should_close_conn = False
        elif user:
            # Create a new connection with user credentials
            username = user.get("username")
            password = user.get("password")

            if not username or not password:
                raise ValueError(
                    "User credentials (username, password) not found in session. Cannot connect to the database.")

            self.conn = get_connection_with_credentials(
                user=username, password=password)
            self.should_close_conn = True
        else:
            raise ValueError(
                "Either user credentials or a connection must be provided")

    def _row_to_dict(self, row: pyodbc.Row) -> Dict[str, str | int | bool | float]:
        """
        Transform pyodbc row to a dictionary with consistent keys.

        Args:
            row: Database row from pyodbc

        Returns:
            Dictionary with standardized keys
        """
        result = {}

        # Map column names to values
        column_names = [column[0] for column in row.cursor_description]
        for i, value in enumerate(row):
            column_name = column_names[i]
            result[column_name] = value

        return result

    def list_loptinchi(
        self,
        nienkhoa: Optional[str] = None,
        hocky: Optional[int] = None,
        makhoa: Optional[str] = None,
        only_available: bool = False
    ) -> List[Dict]:
        """
        Fetch list of class sections with filters.

        Args:
            nienkhoa: Optional academic year filter (e.g., "2023-2024")
            hocky: Optional semester filter (1-3)
            makhoa: Optional khoa code filter
            only_available: If True, only return non-canceled classes

        Returns:
            List of class section dictionaries with additional information

        Raises:
            pyodbc.Error: On database errors
        """
        try:
            cursor = self.conn.cursor()

            # Execute stored procedure with parameters
            cursor.execute(
                "EXEC dbo.SP_LTC_Select ?, ?, ?, ?",
                nienkhoa,
                hocky,
                makhoa,
                1 if only_available else 0
            )

            # Fetch and transform results
            rows = cursor.fetchall()
            return [self._row_to_dict(row) for row in rows]
        except pyodbc.Error as err:
            logger.error(f"Error fetching class sections: {err}")
            raise
        finally:
            # The connection is managed by the service layer
            pass

    def create_loptinchi(
        self,
        nienkhoa: str,
        hocky: int,
        mamh: str,
        nhom: int,
        magv: str,
        makhoa: str,
        sosvtoithieu: int
    ) -> int:
        """
        Create a new class section.

        Args:
            nienkhoa: Academic year (e.g., "2023-2024")
            hocky: Semester (1-3)
            mamh: Subject code
            nhom: Group number
            magv: Lecturer code
            makhoa: Department code
            sosvtoithieu: Minimum number of students

        Returns:
            The newly created MALTC (class section ID)

        Raises:
            pyodbc.Error: On database errors, including constraint violations
        """
        try:
            cursor = self.conn.cursor()

            # Declare local variable to capture output,
            # execute SP, then SELECT to retrieve
            cursor.execute(
                """
                DECLARE @newId INT;
                EXEC dbo.SP_LTC_Upsert @ACTION=?,
                                          @MALTC=@newId OUTPUT,
                                          @NIENKHOA=?,
                                          @HOCKY=?,
                                          @MAMH=?,
                                          @NHOM=?,
                                          @MAGV=?,
                                          @MAKHOA=?,
                                          @SOSVTOITHIEU=?;
                SELECT @newId AS MALTC;
                """,
                "INSERT",
                nienkhoa,
                hocky,
                mamh,
                nhom,
                magv,
                makhoa,
                sosvtoithieu
            )

            # Fetch returned id
            maltc_row = cursor.fetchone()
            maltc = maltc_row[0] if maltc_row else None

            # Commit transaction
            self.conn.commit()
            logger.info(f"Successfully created class section with ID: {maltc}")
            return maltc

        except pyodbc.Error as err:
            self.conn.rollback()
            logger.error(f"Error creating class section: {err}")
            raise
        finally:
            pass

    def update_loptinchi(
        self,
        maltc: int,
        nienkhoa: str,
        hocky: int,
        mamh: str,
        nhom: int,
        magv: str,
        makhoa: str,
        sosvtoithieu: int
    ) -> None:
        """
        Update an existing class section.

        Args:
            maltc: Class section ID
            nienkhoa: Academic year (e.g., "2023-2024")
            hocky: Semester (1-3)
            mamh: Subject code
            nhom: Group number
            magv: Lecturer code
            makhoa: Department code
            sosvtoithieu: Minimum number of students

        Raises:
            pyodbc.Error: On database errors, including constraint violations
        """
        try:
            cursor = self.conn.cursor()

            # Execute stored procedure
            cursor.execute(
                "EXEC dbo.SP_LTC_Upsert @ACTION=?, @MALTC=?, @NIENKHOA=?, @HOCKY=?, @MAMH=?, @NHOM=?, @MAGV=?, @MAKHOA=?, @SOSVTOITHIEU=?",
                "UPDATE",
                maltc,
                nienkhoa,
                hocky,
                mamh,
                nhom,
                magv,
                makhoa,
                sosvtoithieu
            )

            # Commit the transaction
            self.conn.commit()
            logger.info(f"Successfully updated class section: {maltc}")

        except pyodbc.Error as err:
            self.conn.rollback()
            logger.error(f"Error updating class section {maltc}: {err}")
            raise
        finally:
            pass

    def cancel_loptinchi(self, maltc: int) -> None:
        """
        Cancel a class section (soft delete).

        Args:
            maltc: Class section ID

        Raises:
            pyodbc.Error: On database errors
        """
        try:
            cursor = self.conn.cursor()

            # Execute cancel stored procedure
            cursor.execute("EXEC dbo.SP_LTC_Cancel ?", maltc)

            # Commit the transaction
            self.conn.commit()
            logger.info(f"Successfully canceled class section: {maltc}")

        except pyodbc.Error as err:
            self.conn.rollback()
            logger.error(f"Error canceling class section {maltc}: {err}")
            raise
        finally:
            pass

    def restore_loptinchi(self, maltc: int) -> None:
        """
        Restore a previously canceled class section.

        Args:
            maltc: Class section ID

        Raises:
            pyodbc.Error: On database errors
        """
        try:
            cursor = self.conn.cursor()

            # Execute restore stored procedure
            cursor.execute("EXEC dbo.SP_LTC_Restore ?", maltc)

            # Commit the transaction
            self.conn.commit()
            logger.info(f"Successfully restored class section: {maltc}")

        except pyodbc.Error as err:
            self.conn.rollback()
            logger.error(f"Error restoring class section {maltc}: {err}")
            raise
        finally:
            pass

    def register_course(self, masv: str, maltc: int) -> None:
        """
        Register a student for a class section.

        Args:
            masv: Student ID
            maltc: Class section ID

        Raises:
            pyodbc.Error: On database errors
        """
        try:
            cursor = self.conn.cursor()

            # Execute register stored procedure
            cursor.execute("EXEC dbo.SP_DK_Register ?, ?", masv, maltc)

            # Commit the transaction
            self.conn.commit()
            logger.info(
                f"Successfully registered student {masv} for class section {maltc}")

        except pyodbc.Error as err:
            self.conn.rollback()
            logger.error(
                f"Error registering student {masv} for class section {maltc}: {err}")
            raise
        finally:
            pass

    def cancel_registration(self, masv: str, maltc: int) -> None:
        """
        Cancel a student's registration for a class section.

        Args:
            masv: Student ID
            maltc: Class section ID

        Raises:
            pyodbc.Error: On database errors
        """
        try:
            cursor = self.conn.cursor()

            # Execute cancel registration stored procedure
            cursor.execute("EXEC dbo.SP_DK_Cancel ?, ?", masv, maltc)

            # Commit the transaction
            self.conn.commit()
            logger.info(
                f"Successfully canceled registration for student {masv}, class section {maltc}")

        except pyodbc.Error as err:
            self.conn.rollback()
            logger.error(
                f"Error canceling registration for student {masv}, class section {maltc}: {err}")
            raise
        finally:
            pass

    def list_student_registrations(self, masv: str) -> List[Dict]:
        """
        List all class sections a student has registered for.

        Args:
            masv: Student ID

        Returns:
            List of registration dictionaries with class section information

        Raises:
            pyodbc.Error: On database errors
        """
        try:
            cursor = self.conn.cursor()

            # Execute stored procedure
            cursor.execute("EXEC dbo.SP_DK_ListByStudent ?", masv)

            # Fetch and transform results
            rows = cursor.fetchall()
            return [self._row_to_dict(row) for row in rows]

        except pyodbc.Error as err:
            logger.error(
                f"Error listing registrations for student {masv}: {err}")
            raise
        finally:
            pass

    def get_student_info(self, masv: str) -> Optional[Dict]:
        """
        Get basic information about a student.

        Args:
            masv: Student ID

        Returns:
            Dictionary with student information or None if not found

        Raises:
            pyodbc.Error: On database errors
        """
        try:
            cursor = self.conn.cursor()

            # Execute direct query to get student information
            cursor.execute(
                "SELECT MASV, HO, TEN, MALOP FROM dbo.SINHVIEN WHERE MASV = ? AND DANGHIHOC = 0",
                masv
            )

            # Fetch result
            row = cursor.fetchone()
            if not row:
                return None

            return self._row_to_dict(row)

        except pyodbc.Error as err:
            logger.error(f"Error getting student info for {masv}: {err}")
            raise
        finally:
            pass

    def close_connection(self):
        """Close the database connection if it was created by this repository."""
        if hasattr(self, 'conn') and self.conn and hasattr(self, 'should_close_conn') and self.should_close_conn:
            self.conn.close()
            logger.debug("Database connection closed")
