-- ===============================================
-- QLDSV-HTC Authentication Procedures
-- File: 01-auth-procedures.sql
-- Description: Stored procedures for authentication
-- ===============================================

USE [$(DB_NAME)];
GO

-- ===============================================
-- 1. SP_SinhVien_XacThuc - Authenticate student
-- ===============================================
CREATE OR ALTER PROCEDURE [dbo].[SP_SinhVien_XacThuc]
    @MASV NCHAR(10),
    @PASSWORD NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if student exists and password is correct
    IF EXISTS (
        SELECT 1 FROM SINHVIEN 
        WHERE MASV = @MASV 
        AND dbo.FN_SinhVien_KiemTraMatKhau(@MASV, @PASSWORD) = 1
        AND DANGHIHOC = 0
    )
    BEGIN
        -- Return student information
        SELECT 
            sv.MASV,
            sv.HO,
            sv.TEN,
            sv.MALOP,
            sv.PHAI,
            sv.NGAYSINH,
            sv.DIACHI,
            sv.DANGHIHOC
        FROM SINHVIEN sv
        WHERE sv.MASV = @MASV;
    END
    ELSE
    BEGIN
        -- Return empty result for failed authentication
        RETURN;
    END
END
GO

-- ===============================================
-- 2. SP_SinhVien_DanhSach - Get list of students
-- ===============================================
CREATE OR ALTER PROCEDURE [dbo].[SP_SinhVien_DanhSach]
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get all active students
    SELECT 
        sv.MASV,
        sv.HO,
        sv.TEN,
        sv.MALOP
    FROM SINHVIEN sv
    WHERE sv.DANGHIHOC = 0
    ORDER BY sv.TEN, sv.HO;
END
GO

-- ===============================================
-- 3. SP_SinhVien_ThongTin - Get student information
-- ===============================================
CREATE OR ALTER PROCEDURE [dbo].[SP_SinhVien_ThongTin]
    @MASV NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get student information by ID
    SELECT 
        sv.MASV,
        sv.HO,
        sv.TEN,
        sv.MALOP,
        sv.PHAI,
        sv.NGAYSINH,
        sv.DIACHI,
        sv.DANGHIHOC
    FROM SINHVIEN sv
    WHERE sv.MASV = @MASV;
END
GO

-- ===============================================
-- 4. SP_SinhVien_DangKy - Register a new student
-- ===============================================
CREATE OR ALTER PROCEDURE [dbo].[SP_SinhVien_DangKy]
    @MASV NCHAR(10),
    @HO NVARCHAR(50),
    @TEN NVARCHAR(10),
    @MALOP NCHAR(10),
    @PHAI BIT,
    @NGAYSINH DATETIME,
    @DIACHI NVARCHAR(100),
    @PASSWORD NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if student ID already exists
    IF EXISTS (SELECT 1 FROM SINHVIEN WHERE MASV = @MASV)
    BEGIN
        -- Return error code -1 for duplicate student ID
        SELECT -1 AS ResultCode, 'Mã sinh viên đã tồn tại' AS Message;
        RETURN;
    END
    
    -- Check if class exists
    IF NOT EXISTS (SELECT 1 FROM LOP WHERE MALOP = @MALOP)
    BEGIN
        -- Return error code -2 for invalid class
        SELECT -2 AS ResultCode, 'Mã lớp không tồn tại' AS Message;
        RETURN;
    END
    
    BEGIN TRY
        -- Insert new student
        INSERT INTO SINHVIEN (MASV, HO, TEN, MALOP, PHAI, NGAYSINH, DIACHI, PASSWORD, DANGHIHOC)
        VALUES (@MASV, @HO, @TEN, @MALOP, @PHAI, @NGAYSINH, @DIACHI, @PASSWORD, 0);
        
        -- Return success code and student information
        SELECT 
            1 AS ResultCode, 
            'Đăng ký sinh viên thành công' AS Message,
            sv.MASV,
            sv.HO,
            sv.TEN,
            sv.MALOP,
            sv.PHAI,
            sv.NGAYSINH,
            sv.DIACHI,
            sv.DANGHIHOC
        FROM SINHVIEN sv
        WHERE sv.MASV = @MASV;
    END TRY
    BEGIN CATCH
        -- Return error code -3 for other errors
        SELECT 
            -3 AS ResultCode, 
            'Lỗi khi đăng ký sinh viên: ' + ERROR_MESSAGE() AS Message;
    END CATCH
END
GO

-- ===============================================
-- 5. SP_GiangVien_DanhSach - Get list of teachers
-- ===============================================
CREATE OR ALTER PROCEDURE [dbo].[SP_GiangVien_DanhSach]
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get all teachers
    SELECT 
        gv.MAGV,
        gv.HO,
        gv.TEN,
        gv.MAKHOA
    FROM GIANGVIEN gv
    ORDER BY gv.TEN, gv.HO;
END
GO

-- ===============================================
-- 6. SP_GiangVien_ThongTin - Get teacher information
-- ===============================================
CREATE OR ALTER PROCEDURE [dbo].[SP_GiangVien_ThongTin]
    @MAGV NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get teacher information by ID
    SELECT 
        gv.MAGV,
        gv.HO,
        gv.TEN,
        gv.HOCVI,
        gv.HOCHAM,
        gv.CHUYENMON,
        gv.MAKHOA
    FROM GIANGVIEN gv
    WHERE gv.MAGV = @MAGV;
END
GO

-- ===============================================
-- 7. SP_GiangVien_KiemTra - Check if teacher exists
-- ===============================================
CREATE OR ALTER PROCEDURE [dbo].[SP_GiangVien_KiemTra]
    @MAGV NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if teacher exists
    IF EXISTS (
        SELECT 1 FROM GIANGVIEN 
        WHERE MAGV = @MAGV
    )
    BEGIN
        -- Return teacher ID to indicate existence
        SELECT @MAGV AS MAGV;
    END
    ELSE
    BEGIN
        -- Return empty result for non-existent teacher
        RETURN;
    END
END
GO

-- ===============================================
-- 8. SP_GiangVien_DangKy - Register a new teacher
-- ===============================================
CREATE OR ALTER PROCEDURE [dbo].[SP_GiangVien_DangKy]
    @MAGV NCHAR(10),
    @HO NVARCHAR(50),
    @TEN NVARCHAR(10),
    @MAKHOA NCHAR(10),
    @HOCVI NVARCHAR(20) = NULL,
    @HOCHAM NVARCHAR(20) = NULL,
    @CHUYENMON NVARCHAR(50) = NULL,
    @PASSWORD NVARCHAR(50),
    @ROLE NVARCHAR(10) = 'KHOA' -- Default role: KHOA
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if teacher ID already exists
    IF EXISTS (SELECT 1 FROM GIANGVIEN WHERE MAGV = @MAGV)
    BEGIN
        SELECT -1 AS ResultCode, 'Mã giảng viên đã tồn tại' AS Message;
        RETURN;
    END
    
    -- Check if department exists
    IF NOT EXISTS (SELECT 1 FROM KHOA WHERE MAKHOA = @MAKHOA)
    BEGIN
        SELECT -2 AS ResultCode, 'Mã khoa không tồn tại' AS Message;
        RETURN;
    END
    
    -- Validate role
    IF @ROLE NOT IN ('PGV', 'KHOA')
    BEGIN
        SELECT -3 AS ResultCode, 'Role không hợp lệ. Chỉ chấp nhận PGV hoặc KHOA' AS Message;
        RETURN;
    END
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Insert new teacher record
        INSERT INTO GIANGVIEN (MAGV, HO, TEN, MAKHOA, HOCVI, HOCHAM, CHUYENMON)
        VALUES (@MAGV, @HO, @TEN, @MAKHOA, @HOCVI, @HOCHAM, @CHUYENMON);
        
        -- Create SQL Server login for the teacher
        DECLARE @sql NVARCHAR(500);
        
        -- Create login 
        SET @sql = 'USE [master]; CREATE LOGIN [' + @MAGV + '] WITH PASSWORD = ''' + @PASSWORD + ''', DEFAULT_DATABASE=[' + DB_NAME() + ']';
        EXEC sp_executesql @sql;
        
        -- Create database user
        SET @sql = 'CREATE USER [' + @MAGV + '] FOR LOGIN [' + @MAGV + ']';
        EXEC sp_executesql @sql;
        
        -- Add user to appropriate role
        IF @ROLE = 'PGV'
        BEGIN
            SET @sql = 'EXEC sp_addrolemember ''PGV_ROLE'', ''' + @MAGV + '''';
            EXEC sp_executesql @sql;
        END
        ELSE -- KHOA role
        BEGIN
            SET @sql = 'EXEC sp_addrolemember ''KHOA_ROLE'', ''' + @MAGV + '''';
            EXEC sp_executesql @sql;
        END
        
        COMMIT TRANSACTION;
        
        -- Return success and teacher data
        SELECT 
            1 AS ResultCode, 
            'Đăng ký giảng viên thành công' AS Message,
            gv.MAGV,
            gv.HO,
            gv.TEN,
            gv.HOCVI,
            gv.HOCHAM,
            gv.CHUYENMON,
            gv.MAKHOA,
            @ROLE AS ROLE
        FROM GIANGVIEN gv
        WHERE gv.MAGV = @MAGV;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        -- Return error
        SELECT 
            -4 AS ResultCode, 
            'Lỗi khi đăng ký giảng viên: ' + ERROR_MESSAGE() AS Message;
    END CATCH
END
GO

PRINT 'Authentication stored procedures created successfully'; 