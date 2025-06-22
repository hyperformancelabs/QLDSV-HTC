-- Authentication stored procedures for $(DB_NAME) database

USE [$(DB_NAME)];
GO

-- =============================================
-- Description: Trả về thông tin người dùng (giảng viên) dựa trên login name
-- Parameters:  @LOGINNAME - Tên đăng nhập SQL Server
-- Returns:     USERNAME, HOTEN, TENNHOM
-- =============================================
CREATE OR ALTER PROCEDURE dbo.sp_Get_Info_Login
    @LOGINNAME VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Lấy tên user từ login name
    DECLARE @USERNAME NVARCHAR(50) = (SELECT NAME
                                      FROM   sys.sysusers
                                      WHERE  sid = SUSER_SID(@LOGINNAME));
    IF @USERNAME IS NULL
    BEGIN
        RAISERROR(N'Login chưa được map vào database', 16, 1);
        RETURN;
    END

    -- Lấy họ tên giảng viên
    DECLARE @HOTEN NVARCHAR(60) = (SELECT HO + N' ' + TEN
                                   FROM   GIANGVIEN
                                   WHERE  MAGV = @USERNAME);

    -- Tìm role của user (pgv_role hoặc khoa_role)
    DECLARE @TENNHOM NVARCHAR(50);
    SELECT TOP 1 @TENNHOM = dp.NAME
    FROM   sys.database_role_members rm
           JOIN sys.database_principals dp ON dp.principal_id = rm.role_principal_id
    WHERE  rm.member_principal_id = USER_ID(@USERNAME)
          AND dp.NAME IN (N'pgv_role', N'khoa_role');

    -- Trả về kết quả
    SELECT 
        USERNAME = @USERNAME, 
        HOTEN = ISNULL(@HOTEN, N''), 
        TENNHOM = @TENNHOM;
END;
GO

-- =============================================
-- Description: Xác thực sinh viên dựa trên MASV và PASSWORD
-- Parameters:  @MASV - Mã sinh viên
--              @PASSWORD - Mật khẩu sinh viên
-- Returns:     USERNAME, HOTEN, TENNHOM
-- =============================================
CREATE OR ALTER PROCEDURE dbo.sp_Check_Login_SV
    @MASV     NCHAR(10),
    @PASSWORD NVARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra thông tin đăng nhập
    IF NOT EXISTS (SELECT 1
                  FROM   SINHVIEN
                  WHERE  MASV = @MASV
                    AND  PASSWORD = @PASSWORD
                    AND  DANGHIHOC = 0)
    BEGIN
        RAISERROR(N'Sai mã sinh viên hoặc mật khẩu', 16, 1);
        RETURN;
    END

    -- Trả về thông tin sinh viên
    SELECT 
        USERNAME = @MASV,
        HOTEN = (SELECT HO + N' ' + TEN FROM SINHVIEN WHERE MASV = @MASV),
        TENNHOM = N'sv_role';
END;
GO

-- =============================================
-- Description: Tạo tài khoản đăng nhập và gán quyền
-- Parameters:  @LOGINNAME - Tên đăng nhập SQL Server
--              @PASSWORD - Mật khẩu
--              @USERID - Tên user trong database
--              @ROLE - Nhóm quyền (pgv_role/khoa_role/sv_role)
-- =============================================
CREATE OR ALTER PROCEDURE dbo.sp_TaoTaiKhoan
    @LOGINNAME SYSNAME,
    @PASSWORD  NVARCHAR(128),
    @USERID    SYSNAME,
    @ROLE      SYSNAME
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra tham số ROLE hợp lệ
    IF @ROLE NOT IN (N'pgv_role', N'khoa_role', N'sv_role')
    BEGIN
        RAISERROR(N'ROLE không hợp lệ', 16, 1);
        RETURN;
    END;

    -- Kiểm tra login đã tồn tại
    IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @LOGINNAME)
    BEGIN
        RAISERROR(N'Login đã tồn tại', 16, 1);
        RETURN;
    END;

    -- Kiểm tra user đã tồn tại trong database
    IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @USERID)
    BEGIN
        RAISERROR(N'UserID đã tồn tại trong database', 16, 1);
        RETURN;
    END;

    -- Tạo LOGIN với CHECK_POLICY OFF để chấp nhận password đơn giản
    DECLARE @sql NVARCHAR(MAX) = N'CREATE LOGIN ' + QUOTENAME(@LOGINNAME) 
                              + N' WITH PASSWORD = ' + QUOTENAME(@PASSWORD, '''') 
                              + N', CHECK_POLICY = OFF';
    EXEC (@sql);

    -- Map LOGIN -> USER trong database hiện tại
    SET @sql = N'CREATE USER ' + QUOTENAME(@USERID) 
             + N' FOR LOGIN ' + QUOTENAME(@LOGINNAME) + N';';
    EXEC (@sql);

    -- Thêm USER vào ROLE
    SET @sql = N'ALTER ROLE ' + QUOTENAME(@ROLE) 
             + N' ADD MEMBER ' + QUOTENAME(@USERID);
    EXEC (@sql);
END;
GO

-- =============================================
-- Description: Thêm sinh viên mới vào hệ thống
-- Parameters:  @MASV - Mã sinh viên
--              @HO - Họ sinh viên
--              @TEN - Tên sinh viên
--              @MALOP - Mã lớp
--              @PHAI - Giới tính (0: Nam, 1: Nữ)
--              @NGAYSINH - Ngày sinh
--              @DIACHI - Địa chỉ
--              @PASSWORD - Mật khẩu (mặc định: 123456)
-- =============================================
CREATE OR ALTER PROCEDURE dbo.sp_Them_SinhVien
    @MASV     NCHAR(10),
    @HO       NVARCHAR(50),
    @TEN      NVARCHAR(10),
    @MALOP    NCHAR(10),
    @PHAI     BIT           = 0,
    @NGAYSINH DATETIME      = NULL,
    @DIACHI   NVARCHAR(100) = NULL,
    @PASSWORD NVARCHAR(40)  = N'123456'
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra trùng mã sinh viên
    IF EXISTS (SELECT 1 FROM SINHVIEN WHERE MASV = @MASV)
    BEGIN
        RAISERROR(N'Mã sinh viên đã tồn tại', 16, 1);
        RETURN;
    END;

    -- Thêm sinh viên mới
    INSERT INTO SINHVIEN (MASV, HO, TEN, MALOP, PHAI, NGAYSINH, DIACHI, PASSWORD)
    VALUES (@MASV, @HO, @TEN, @MALOP, @PHAI, @NGAYSINH, @DIACHI, @PASSWORD);
END;
GO

-- =============================================
-- Description: Thêm giảng viên mới và tạo tài khoản đăng nhập
-- Parameters:  @LOGINNAME - Tên đăng nhập SQL Server
--              @MAGV - Mã giảng viên (sẽ là tên USER trong DB)
--              @HO - Họ giảng viên
--              @TEN - Tên giảng viên
--              @MAKHOA - Mã khoa
--              @ROLE - Nhóm quyền (pgv_role/khoa_role)
--              @PASSWORD - Mật khẩu (bắt buộc)
--              @HOCVI - Học vị
--              @HOCHAM - Học hàm
--              @CHUYENMON - Chuyên môn
-- =============================================
CREATE OR ALTER PROCEDURE dbo.sp_Them_GiangVien
    @LOGINNAME SYSNAME,
    @MAGV      NCHAR(10),
    @HO        NVARCHAR(50),
    @TEN       NVARCHAR(10),
    @MAKHOA    NCHAR(10),
    @ROLE      SYSNAME,
    @PASSWORD  NVARCHAR(128),
    @HOCVI     NVARCHAR(20) = NULL,
    @HOCHAM    NVARCHAR(20) = NULL,
    @CHUYENMON NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra role hợp lệ
    IF @ROLE NOT IN (N'pgv_role', N'khoa_role')
    BEGIN
        RAISERROR(N'ROLE phải là pgv_role hoặc khoa_role', 16, 1);
        RETURN;
    END;

    -- Kiểm tra trùng mã giảng viên
    IF EXISTS (SELECT 1 FROM GIANGVIEN WHERE MAGV = @MAGV)
    BEGIN
        RAISERROR(N'Mã giảng viên đã tồn tại', 16, 1);
        RETURN;
    END;

    -- Thêm giảng viên mới
    INSERT INTO GIANGVIEN (MAGV, HO, TEN, MAKHOA, HOCVI, HOCHAM, CHUYENMON)
    VALUES (@MAGV, @HO, @TEN, @MAKHOA, @HOCVI, @HOCHAM, @CHUYENMON);

    -- Tạo tài khoản đăng nhập cho giảng viên
    EXEC dbo.sp_TaoTaiKhoan 
        @LOGINNAME = @LOGINNAME,
        @PASSWORD  = @PASSWORD,
        @USERID    = @MAGV,
        @ROLE      = @ROLE;
END;
GO

-- =============================================
-- Phân quyền thực thi stored procedure
-- =============================================
-- Sinh viên chỉ được phép đăng nhập
GRANT EXECUTE ON dbo.sp_Check_Login_SV TO sv_role;

-- Giảng viên được phép xem thông tin và tạo tài khoản
GRANT EXECUTE ON dbo.sp_Get_Info_Login TO pgv_role, khoa_role;
GRANT EXECUTE ON dbo.sp_TaoTaiKhoan TO pgv_role;

-- Thêm sinh viên và giảng viên chỉ dành cho PGV
GRANT EXECUTE ON dbo.sp_Them_SinhVien TO pgv_role;
GRANT EXECUTE ON dbo.sp_Them_GiangVien TO pgv_role;
GO