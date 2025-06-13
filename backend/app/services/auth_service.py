"""
Authentication service for QLDSV-HTC

This module provides authentication functionality for students and staff.
"""

from typing import Dict, Optional, List, Tuple
from fastapi import HTTPException, Request, Response
from app.db import execute_sql_query
from app.core.logger import setup_logger
from app.core.config import get_settings

# Setup logger
logger = setup_logger("services.auth")

# Get settings
settings = get_settings()


class AuthService:
    """Authentication service for QLDSV-HTC"""

    @staticmethod
    def authenticate_student(masv: str, password: str) -> Dict:
        """
        Authenticate a student with MASV and password

        Args:
            masv: Student ID
            password: Student password

        Returns:
            Dict: Student information if authentication successful

        Raises:
            HTTPException: If authentication fails
        """
        try:
            # Use stored procedure for authentication
            query = f"EXEC SP_SinhVien_XacThuc @MASV='{masv}', @PASSWORD='{password}'"

            # Use app_user (high privilege) for authentication
            result = execute_sql_query(
                query, user_type=settings.DB_DEFAULT_USER)

            # Check if any result was returned
            if not result or "No rows affected" in result:
                logger.warning(f"Failed login attempt for student ID: {masv}")
                raise HTTPException(
                    status_code=401, detail="Invalid credentials or student is not active")

            # Parse the result
            # Format is typically: "MASV,HO,TEN,MALOP,PHAI,NGAYSINH,DIACHI,DANGHIHOC"
            parts = result.strip().split(',')
            if len(parts) < 8:
                logger.error(
                    f"Unexpected result format for student authentication: {result}")
                raise HTTPException(
                    status_code=500, detail="Unexpected server response")

            # Convert PHAI (0/1) to boolean
            phai = parts[4].strip() == "1"

            # Convert DANGHIHOC (0/1) to boolean
            danghihoc = parts[7].strip() == "1"

            student_info = {
                "masv": parts[0].strip(),
                "ho": parts[1].strip(),
                "ten": parts[2].strip(),
                "malop": parts[3].strip(),
                "phai": phai,
                "ngaysinh": parts[5].strip() if parts[5].strip() else None,
                "diachi": parts[6].strip() if parts[6].strip() else None,
                "danghihoc": danghihoc,
                "role": "SV"  # Role is always SV for students
            }

            logger.info(
                f"Student authenticated successfully: {student_info['masv']}")
            return student_info

        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error during student authentication: {e}")
            raise HTTPException(
                status_code=500, detail=f"Authentication error: {str(e)}")

    @staticmethod
    def get_all_students() -> List[Dict]:
        """
        Get all students for dropdown selection

        Returns:
            List[Dict]: List of students with basic info
        """
        try:
            query = "SELECT MASV, HO, TEN, MALOP FROM SINHVIEN WHERE DANGHIHOC = 0 ORDER BY TEN, HO"
            result = execute_sql_query(query)

            if not result:
                return []

            students = []
            for row in result.strip().split('\n'):
                parts = row.split(',')
                if len(parts) >= 4:
                    student = {
                        "masv": parts[0].strip(),
                        "ho": parts[1].strip(),
                        "ten": parts[2].strip(),
                        "malop": parts[3].strip(),
                        "display_name": f"{parts[1].strip()} {parts[2].strip()}"
                    }
                    students.append(student)

            return students
        except Exception as e:
            logger.error(f"Error getting all students: {e}")
            return []

    @staticmethod
    def search_students_by_name(search_term: str) -> List[Dict]:
        """
        Search students by name (ho + ten)

        Args:
            search_term: Search term for student name

        Returns:
            List[Dict]: List of matching students with basic info for dropdown
        """
        try:
            # Use LIKE operator for case-insensitive search
            query = f"""
            SELECT MASV, HO, TEN 
            FROM SINHVIEN 
            WHERE DANGHIHOC = 0 AND (HO + ' ' + TEN LIKE N'%{search_term}%' OR MASV LIKE '{search_term}%')
            ORDER BY TEN, HO, MASV
            """
            result = execute_sql_query(query)

            if not result:
                return []

            students = []
            name_counts = {}  # To track duplicate names for display

            for row in result.strip().split('\n'):
                parts = row.split(',')
                if len(parts) >= 3:
                    full_name = f"{parts[1].strip()} {parts[2].strip()}"

                    # Track duplicate names
                    if full_name in name_counts:
                        name_counts[full_name] += 1
                        display_name = f"{full_name} {name_counts[full_name]}"
                    else:
                        name_counts[full_name] = 1
                        display_name = full_name

                    student = {
                        "masv": parts[0].strip(),
                        "ho": parts[1].strip(),
                        "ten": parts[2].strip(),
                        "display_name": display_name
                    }
                    students.append(student)

            return students
        except Exception as e:
            logger.error(f"Error searching students by name: {e}")
            return []

    @staticmethod
    def get_student_by_id(masv: str) -> Dict:
        """
        Get student information by ID

        Args:
            masv: Student ID

        Returns:
            Dict: Student information
        """
        try:
            # Use stored procedure to get student information
            query = f"EXEC SP_SinhVien_ThongTin @MASV='{masv}'"

            # Use app_user (high privilege) for retrieving student information
            result = execute_sql_query(
                query, user_type=settings.DB_DEFAULT_USER)

            if not result or "No rows affected" in result:
                raise HTTPException(
                    status_code=404, detail=f"Student with ID {masv} not found")

            # Parse the result
            parts = result.strip().split(',')
            if len(parts) < 8:
                logger.error(
                    f"Unexpected result format for student lookup: {result}")
                raise HTTPException(
                    status_code=500, detail="Unexpected server response")

            # Convert PHAI (0/1) to boolean
            phai = parts[4].strip() == "1"

            # Convert DANGHIHOC (0/1) to boolean
            danghihoc = parts[7].strip() == "1"

            student_info = {
                "masv": parts[0].strip(),
                "ho": parts[1].strip(),
                "ten": parts[2].strip(),
                "malop": parts[3].strip(),
                "phai": phai,
                "ngaysinh": parts[5].strip() if parts[5].strip() else None,
                "diachi": parts[6].strip() if parts[6].strip() else None,
                "danghihoc": danghihoc
            }

            return student_info

        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error retrieving student by ID: {e}")
            raise HTTPException(
                status_code=500, detail=f"Error retrieving student: {str(e)}")

    @staticmethod
    def register_student(
        masv: str,
        ho: str,
        ten: str,
        malop: str,
        phai: bool,
        ngaysinh: str,
        diachi: str,
        password: str
    ) -> Dict:
        """
        Register a new student

        Args:
            masv: Student ID
            ho: Last name
            ten: First name
            malop: Class ID
            phai: Gender (True for female, False for male)
            ngaysinh: Date of birth
            diachi: Address
            password: Password

        Returns:
            Dict: Registration result with status and message

        Raises:
            HTTPException: If registration fails
        """
        try:
            # Use stored procedure for student registration
            query = f"""
            EXEC SP_SinhVien_DangKy 
                @MASV='{masv}', 
                @HO=N'{ho}', 
                @TEN=N'{ten}', 
                @MALOP='{malop}', 
                @PHAI={1 if phai else 0}, 
                @NGAYSINH='{ngaysinh}', 
                @DIACHI=N'{diachi}', 
                @PASSWORD='{password}'
            """

            # Use app_user (high privilege) for registration
            result = execute_sql_query(
                query, user_type=settings.DB_DEFAULT_USER)

            if not result or "No rows affected" in result:
                logger.error(
                    f"Empty result from student registration procedure")
                raise HTTPException(
                    status_code=500, detail="Registration failed: Empty response from server")

            # Parse the result
            lines = result.strip().split('\n')
            if not lines:
                raise HTTPException(
                    status_code=500, detail="Registration failed: Invalid server response")

            first_line = lines[0].split(',')
            if len(first_line) < 2:
                raise HTTPException(
                    status_code=500, detail="Registration failed: Invalid server response format")

            result_code = int(first_line[0].strip())
            message = first_line[1].strip()

            if result_code < 0:
                # Registration failed
                logger.warning(f"Student registration failed: {message}")
                raise HTTPException(status_code=400, detail=message)

            # Registration successful
            logger.info(f"Student registered successfully: {masv}")

            # If we have student data in the response
            if len(first_line) >= 10:
                # Parse student info from result
                phai_value = first_line[6].strip() == "1"
                danghihoc_value = first_line[9].strip() == "1"

                return {
                    "success": True,
                    "message": message,
                    "student": {
                        "masv": first_line[2].strip(),
                        "ho": first_line[3].strip(),
                        "ten": first_line[4].strip(),
                        "malop": first_line[5].strip(),
                        "phai": phai_value,
                        "ngaysinh": first_line[7].strip() if first_line[7].strip() else None,
                        "diachi": first_line[8].strip() if first_line[8].strip() else None,
                        "danghihoc": danghihoc_value,
                        "role": "SV"
                    }
                }

            # Basic success response if no student data
            return {
                "success": True,
                "message": message
            }

        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error during student registration: {e}")
            raise HTTPException(
                status_code=500, detail=f"Registration error: {str(e)}")

    @staticmethod
    def test_sql_server_login(username: str, password: str) -> bool:
        """
        Test SQL Server login credentials by attempting to connect and execute a simple query

        For regular teachers, this tests actual SQL Server login as required by DESCRIPTION.md
        For system users, this uses the SQL executor with the user's credentials

        Args:
            username: SQL Server username
            password: SQL Server password

        Returns:
            bool: True if authentication successful, False otherwise
        """
        logger.info(f"Testing SQL Server login for user: {username}")

        # For system users (pgv_user, khoa_user), use the SQL executor
        if username in ['pgv_user', 'khoa_user']:
            try:
                # Use execute_sql_query with the specific user type
                result = execute_sql_query(
                    "SELECT @@VERSION", user_type=username)
                if result and "Microsoft SQL Server" in result:
                    logger.info(
                        f"SQL Server authentication successful for system user: {username}")
                    return True
                else:
                    logger.warning(
                        f"SQL Server authentication failed for system user: {username}")
                    return False
            except Exception as e:
                logger.warning(
                    f"SQL Server authentication failed for system user {username}: {e}")
                return False

        # For regular teachers, try pyodbc first, then fallback to verify in database
        try:
            import pyodbc

            # Build connection string with shorter timeout for faster response
            connection_string = (
                f"DRIVER={{ODBC Driver 18 for SQL Server}};"
                f"SERVER={settings.DB_HOST},{settings.DB_PORT};"
                f"DATABASE={settings.DB_NAME};"
                f"UID={username};"
                f"PWD={password};"
                f"TrustServerCertificate=yes;"
                f"Encrypt=yes;"
                f"LoginTimeout=5;"  # Shorter timeout
            )

            # Try to connect and execute a simple query
            with pyodbc.connect(connection_string, timeout=5) as conn:
                cursor = conn.cursor()
                cursor.execute("SELECT @@VERSION")
                result = cursor.fetchone()

                if result:
                    logger.info(
                        f"SQL Server authentication successful for teacher: {username}")
                    return True
                else:
                    logger.warning(
                        f"SQL Server authentication failed for teacher: {username}")
                    return False

        except pyodbc.Error as e:
            error_msg = str(e)
            logger.warning(
                f"ODBC authentication failed for teacher {username}: {error_msg}")

            # If it's a timeout or connection issue, check if fallback is enabled
            if "timeout" in error_msg.lower() or "connection" in error_msg.lower():
                logger.warning(
                    f"ODBC timeout for {username}, cannot verify SQL Server credentials")

                # Check if fallback authentication is enabled for development
                if settings.ENABLE_TEACHER_FALLBACK_AUTH and settings.DEVELOPMENT_MODE:
                    logger.warning(
                        f"DEVELOPMENT MODE: Enabling fallback authentication for {username}")
                    logger.warning(
                        f"⚠️  This bypasses SQL Server authentication - DO NOT use in production!")

                    # Enhanced password validation for fallback
                    if password and len(password) >= 8:
                        # Check password has some complexity (letters + numbers)
                        has_letter = any(c.isalpha() for c in password)
                        has_digit = any(c.isdigit() for c in password)

                        if has_letter and has_digit:
                            logger.warning(
                                f"Fallback authentication successful for {username} (DEVELOPMENT ONLY)")
                            return True
                        else:
                            logger.warning(
                                f"Fallback authentication failed for {username}: password too simple")
                            return False
                    else:
                        logger.warning(
                            f"Fallback authentication failed for {username}: password too short (min 8 chars)")
                        return False
                else:
                    # Production mode or fallback disabled - deny login
                    logger.warning(
                        f"Denying login for {username} due to inability to verify SQL Server authentication")
                    logger.warning(
                        f"To enable fallback auth in development, set ENABLE_TEACHER_FALLBACK_AUTH=true")
                    return False
            else:
                # Authentication failure (wrong credentials)
                logger.warning(
                    f"SQL Server authentication failed for {username}: wrong credentials")
                return False

        except ImportError:
            logger.error(
                "pyodbc not available - cannot verify SQL Server authentication")

            # Check if fallback authentication is enabled for development
            if settings.ENABLE_TEACHER_FALLBACK_AUTH and settings.DEVELOPMENT_MODE:
                logger.warning(
                    f"DEVELOPMENT MODE: pyodbc not available, enabling fallback for {username}")
                logger.warning(
                    f"⚠️  This bypasses SQL Server authentication - install pyodbc for production!")

                # Enhanced password validation for fallback
                if password and len(password) >= 8:
                    has_letter = any(c.isalpha() for c in password)
                    has_digit = any(c.isdigit() for c in password)

                    if has_letter and has_digit:
                        logger.warning(
                            f"Fallback authentication successful for {username} (DEVELOPMENT ONLY)")
                        return True
                    else:
                        logger.warning(
                            f"Fallback authentication failed for {username}: password too simple")
                        return False
                else:
                    logger.warning(
                        f"Fallback authentication failed for {username}: password too short (min 8 chars)")
                    return False
            else:
                logger.warning(
                    f"Denying login for {username} due to missing ODBC driver")
                # According to DESCRIPTION.md, we MUST verify SQL Server authentication
                # If pyodbc is not available, we cannot allow teacher login
                return False

        except Exception as e:
            logger.error(
                f"Unexpected error testing SQL Server login for user {username}: {e}")
            return False

    @staticmethod
    def authenticate_teacher(magv: str, password: str) -> Dict:
        """
        Authenticate a teacher with MAGV and SQL Server login password

        According to DESCRIPTION.md requirements, teachers must login through SQL Server login.
        This method tests the actual SQL Server connection with provided credentials.

        Args:
            magv: Teacher ID (also used as SQL Server login)
            password: SQL Server login password

        Returns:
            Dict: Teacher information with role if authentication successful

        Raises:
            HTTPException: If authentication fails
        """
        try:
            logger.info(f"Attempting to authenticate teacher with ID: {magv}")

            # Special case for system users (pgv_user, khoa_user)
            is_system_user = magv in ['pgv_user', 'khoa_user']
            logger.info(f"Is system user: {is_system_user}")

            if is_system_user:
                # For system users, check password against settings
                if magv == 'pgv_user':
                    expected_password = settings.MSSQL_PGV_PASSWORD
                    role = "PGV"
                    display_name = "Phòng Giáo Vụ"
                elif magv == 'khoa_user':
                    expected_password = settings.MSSQL_KHOA_PASSWORD
                    role = "KHOA"
                    display_name = "Quản Lý Khoa"
                else:
                    raise HTTPException(
                        status_code=401, detail="Invalid system user")

                if password != expected_password:
                    logger.warning(f"Invalid password for system user {magv}")
                    raise HTTPException(
                        status_code=401, detail="Invalid credentials")

                # Test the actual SQL Server connection
                if not AuthService.test_sql_server_login(magv, password):
                    logger.warning(
                        f"SQL Server connection failed for system user {magv}")
                    raise HTTPException(
                        status_code=401, detail="SQL Server authentication failed")

                teacher_info = {
                    "magv": magv,
                    "ho": display_name,
                    "ten": "Admin",
                    "hocvi": "System",
                    "hocham": "Admin",
                    "chuyenmon": "Quản trị hệ thống",
                    "makhoa": "ADMIN",
                    "role": role
                }
                logger.info(f"System user authenticated successfully: {magv}")
                return teacher_info

            else:
                # For regular teachers, first check if they exist in database
                check_query = f"EXEC SP_GiangVien_KiemTra @MAGV='{magv}'"
                check_result = execute_sql_query(
                    check_query, user_type=settings.DB_DEFAULT_USER)

                if not check_result or "No rows affected" in check_result:
                    logger.warning(f"Teacher ID not found in database: {magv}")
                    raise HTTPException(
                        status_code=401, detail="Invalid teacher ID")

                # Test SQL Server login with teacher credentials
                logger.info(f"Testing SQL Server login for teacher: {magv}")
                if not AuthService.test_sql_server_login(magv, password):
                    logger.warning(
                        f"SQL Server authentication failed for teacher {magv}")
                    raise HTTPException(
                        status_code=401, detail="Invalid SQL Server credentials")

                # If SQL Server authentication successful, get teacher information
                query = f"EXEC SP_GiangVien_ThongTin @MAGV='{magv}'"
                teacher_info_result = execute_sql_query(
                    query, user_type=settings.DB_DEFAULT_USER)

                if not teacher_info_result:
                    raise HTTPException(
                        status_code=500, detail="Failed to retrieve teacher information")

                # Parse the result - format: MAGV,HO,TEN,HOCVI,HOCHAM,CHUYENMON,MAKHOA
                parts = teacher_info_result.strip().split(',')
                if len(parts) < 7:
                    logger.error(
                        f"Unexpected teacher info format: {teacher_info_result}")
                    raise HTTPException(
                        status_code=500, detail="Unexpected server response")

                # Determine role based on database role membership
                makhoa = parts[6].strip() if len(parts) > 6 else ""

                # Check if teacher has PGV role in database
                role_query = f"""
                SELECT r.name AS RoleName 
                FROM sys.database_principals dp
                JOIN sys.database_role_members rm ON dp.principal_id = rm.member_principal_id
                JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
                WHERE dp.name = '{magv}' AND r.name IN ('PGV_ROLE', 'KHOA_ROLE', 'SV_ROLE')
                """

                role_result = execute_sql_query(
                    role_query, user_type=settings.DB_DEFAULT_USER)

                if role_result and "PGV_ROLE" in role_result:
                    role = "PGV"
                elif role_result and "KHOA_ROLE" in role_result:
                    role = "KHOA"
                else:
                    role = "KHOA"  # Default role for regular teachers

                teacher_info = {
                    "magv": parts[0].strip(),
                    "ho": parts[1].strip(),
                    "ten": parts[2].strip(),
                    "hocvi": parts[3].strip() if len(parts) > 3 and parts[3].strip() else None,
                    "hocham": parts[4].strip() if len(parts) > 4 and parts[4].strip() else None,
                    "chuyenmon": parts[5].strip() if len(parts) > 5 and parts[5].strip() else None,
                    "makhoa": makhoa,
                    "role": role
                }

                logger.info(
                    f"Teacher authenticated successfully: {teacher_info['magv']}")
                return teacher_info

        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error during teacher authentication: {e}")
            raise HTTPException(
                status_code=500, detail=f"Authentication error: {str(e)}")

    @staticmethod
    def get_all_teachers() -> List[Dict]:
        """
        Get all teachers for dropdown selection

        Returns:
            List[Dict]: List of teachers with basic info
        """
        try:
            query = "SELECT MAGV, HO, TEN, MAKHOA FROM GIANGVIEN ORDER BY TEN, HO"
            result = execute_sql_query(query)

            if not result:
                return []

            teachers = []
            for row in result.strip().split('\n'):
                parts = row.split(',')
                if len(parts) >= 4:
                    teacher = {
                        "magv": parts[0].strip(),
                        "ho": parts[1].strip(),
                        "ten": parts[2].strip(),
                        "makhoa": parts[3].strip(),
                        "display_name": f"{parts[1].strip()} {parts[2].strip()}"
                    }
                    teachers.append(teacher)

            return teachers
        except Exception as e:
            logger.error(f"Error getting all teachers: {e}")
            return []

    @staticmethod
    def search_teachers_by_name(search_term: str) -> List[Dict]:
        """
        Search teachers by name (ho + ten)

        Args:
            search_term: Search term for teacher name

        Returns:
            List[Dict]: List of matching teachers with basic info for dropdown
        """
        try:
            # Use LIKE operator for case-insensitive search
            query = f"""
            SELECT MAGV, HO, TEN 
            FROM GIANGVIEN 
            WHERE (HO + ' ' + TEN LIKE N'%{search_term}%' OR MAGV LIKE '{search_term}%')
            ORDER BY TEN, HO, MAGV
            """
            result = execute_sql_query(query)

            if not result:
                return []

            teachers = []
            name_counts = {}  # To track duplicate names for display

            for row in result.strip().split('\n'):
                parts = row.split(',')
                if len(parts) >= 3:
                    full_name = f"{parts[1].strip()} {parts[2].strip()}"

                    # Track duplicate names
                    if full_name in name_counts:
                        name_counts[full_name] += 1
                        display_name = f"{full_name} {name_counts[full_name]}"
                    else:
                        name_counts[full_name] = 1
                        display_name = full_name

                    teacher = {
                        "magv": parts[0].strip(),
                        "ho": parts[1].strip(),
                        "ten": parts[2].strip(),
                        "display_name": display_name
                    }
                    teachers.append(teacher)

            return teachers
        except Exception as e:
            logger.error(f"Error searching teachers by name: {e}")
            return []

    @staticmethod
    def get_teacher_by_id(magv: str) -> Dict:
        """
        Get teacher information by ID

        Args:
            magv: Teacher ID

        Returns:
            Dict: Teacher information
        """
        try:
            # Use stored procedure to get teacher information
            query = f"EXEC SP_GiangVien_ThongTin @MAGV='{magv}'"

            # Use app_user (high privilege) for retrieving teacher information
            result = execute_sql_query(
                query, user_type=settings.DB_DEFAULT_USER)

            if not result or "No rows affected" in result:
                raise HTTPException(
                    status_code=404, detail=f"Teacher with ID {magv} not found")

            # Parse the result - format: MAGV,HO,TEN,HOCVI,HOCHAM,CHUYENMON,MAKHOA
            parts = result.strip().split(',')

            teacher_info = {
                "magv": parts[0].strip(),
                "ho": parts[1].strip(),
                "ten": parts[2].strip(),
                "hocvi": parts[3].strip() if len(parts) > 3 and parts[3].strip() else None,
                "hocham": parts[4].strip() if len(parts) > 4 and parts[4].strip() else None,
                "chuyenmon": parts[5].strip() if len(parts) > 5 and parts[5].strip() else None,
                "makhoa": parts[6].strip() if len(parts) > 6 else "",
            }

            return teacher_info

        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error retrieving teacher by ID: {e}")
            raise HTTPException(
                status_code=500, detail=f"Error retrieving teacher: {str(e)}")

    @staticmethod
    def register_teacher(
        magv: str,
        ho: str,
        ten: str,
        makhoa: str,
        hocvi: Optional[str] = None,
        hocham: Optional[str] = None,
        chuyenmon: Optional[str] = None,
        password: str = None,
        role: str = "KHOA"  # Default to KHOA role
    ) -> Dict:
        """
        Register a new teacher

        Args:
            magv: Teacher ID (will also be the SQL login name)
            ho: Last name
            ten: First name
            makhoa: Department ID
            hocvi: Academic degree (optional)
            hocham: Academic title (optional)
            chuyenmon: Specialization (optional)
            password: SQL Server login password
            role: User role (PGV or KHOA, defaults to KHOA)

        Returns:
            Dict: Registration result with status and message

        Raises:
            HTTPException: If registration fails
        """
        try:
            # Use stored procedure for teacher registration that also creates SQL Server login
            query = f"""
            EXEC SP_GiangVien_DangKy 
                @MAGV='{magv}', 
                @HO=N'{ho}', 
                @TEN=N'{ten}', 
                @MAKHOA='{makhoa}', 
                @HOCVI=N'{hocvi or ""}', 
                @HOCHAM=N'{hocham or ""}', 
                @CHUYENMON=N'{chuyenmon or ""}',
                @PASSWORD='{password or ""}',
                @ROLE='{role}'
            """

            # Use app_user (high privilege) for registration
            result = execute_sql_query(
                query, user_type=settings.DB_DEFAULT_USER)

            if not result or "No rows affected" in result:
                logger.error(
                    f"Empty result from teacher registration procedure")
                raise HTTPException(
                    status_code=500, detail="Registration failed: Empty response from server")

            # Parse the result
            lines = result.strip().split('\n')
            if not lines:
                raise HTTPException(
                    status_code=500, detail="Registration failed: Invalid server response")

            first_line = lines[0].split(',')
            if len(first_line) < 2:
                raise HTTPException(
                    status_code=500, detail="Registration failed: Invalid server response format")

            result_code = int(first_line[0].strip())
            message = first_line[1].strip()

            if result_code < 0:
                # Registration failed
                logger.warning(f"Teacher registration failed: {message}")
                raise HTTPException(status_code=400, detail=message)

            # Registration successful
            logger.info(f"Teacher registered successfully: {magv}")

            # If we have teacher data in the response
            if len(first_line) >= 9:
                # Parse teacher info from result
                return {
                    "success": True,
                    "message": message,
                    "teacher": {
                        "magv": first_line[2].strip(),
                        "ho": first_line[3].strip(),
                        "ten": first_line[4].strip(),
                        "hocvi": first_line[5].strip() if first_line[5].strip() else None,
                        "hocham": first_line[6].strip() if first_line[6].strip() else None,
                        "chuyenmon": first_line[7].strip() if first_line[7].strip() else None,
                        "makhoa": first_line[8].strip(),
                        "role": role
                    }
                }

            # Basic success response if no teacher data
            return {
                "success": True,
                "message": message
            }

        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error during teacher registration: {e}")
            raise HTTPException(
                status_code=500, detail=f"Registration error: {str(e)}")

    @staticmethod
    def manage_session(request: Request, response: Response, student_info: Optional[Dict] = None) -> None:
        """
        Manage user session (create or destroy)

        Args:
            request: FastAPI request object
            response: FastAPI response object
            student_info: User information to store in session (None to destroy session)
        """
        if student_info:
            # Set session data
            request.session["authenticated"] = True
            request.session["user"] = student_info
            # Store user type based on role
            if student_info.get("role") == "SV":
                request.session["user_type"] = "student"
            else:
                request.session["user_type"] = "teacher"
        else:
            # Clear session data
            request.session.clear()
