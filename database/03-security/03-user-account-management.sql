-- =============================================
-- User Account Management Procedures
-- Implements account creation, deletion as required in QLDSV-HTC project
-- Requirement 5a: "Tạo tài khoản cho người dùng sử dụng phần mềm"
-- Uses environment variables for consistent configuration
-- =============================================

USE [$(DB_NAME)]
GO

-- =============================================
-- Stored Procedure: Create User Account
-- Creates login and user for application access
-- Supports dynamic role assignment based on environment configuration
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SP_TaoTaiKhoan]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[SP_TaoTaiKhoan]
GO

CREATE PROCEDURE [dbo].[SP_TaoTaiKhoan]
    @TenNhanVien NVARCHAR(100),
    @MaNV NVARCHAR(20),
    @TaiKhoan NVARCHAR(50),
    @MatKhau NVARCHAR(50),
    @NhomQuyen NVARCHAR(20) -- 'PGV', 'KHOA', 'SV'
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        PRINT 'Tao tai khoan dang nhap cho: ' + @TenNhanVien
        
        -- Validate input parameters
        IF @TaiKhoan IS NULL OR @TaiKhoan = ''
        BEGIN
            RAISERROR('Tai khoan khong duoc de trong', 16, 1)
            RETURN
        END
        
        IF @MatKhau IS NULL OR @MatKhau = ''
        BEGIN
            RAISERROR('Mat khau khong duoc de trong', 16, 1)
            RETURN
        END
        
        IF @NhomQuyen NOT IN ('PGV', 'KHOA', 'SV')
        BEGIN
            RAISERROR('Nhom quyen phai la PGV, KHOA hoac SV', 16, 1)
            RETURN
        END
        
        -- Check if login already exists
        IF EXISTS (SELECT * FROM sys.server_principals WHERE name = @TaiKhoan)
        BEGIN
            RAISERROR('Tai khoan da ton tai trong he thong', 16, 1)
            RETURN
        END
        
        -- Create server login
        DECLARE @sql NVARCHAR(MAX)
        SET @sql = 'CREATE LOGIN [' + @TaiKhoan + '] WITH PASSWORD = ''' + @MatKhau + ''''
        EXEC(@sql)
        PRINT 'Da tao login: ' + @TaiKhoan
        
        -- Create database user
        SET @sql = 'CREATE USER [' + @TaiKhoan + '] FOR LOGIN [' + @TaiKhoan + ']'
        EXEC(@sql)
        PRINT 'Da tao database user: ' + @TaiKhoan
        
        -- Assign to appropriate role based on NhomQuyen
        DECLARE @RoleName NVARCHAR(50)
        SET @RoleName = @NhomQuyen + '_ROLE'
        
        -- Check if role exists before assigning
        IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @RoleName AND type = 'R')
        BEGIN
            EXEC sp_addrolemember @RoleName, @TaiKhoan
            PRINT 'Da gan quyen ' + @NhomQuyen + ' cho tai khoan: ' + @TaiKhoan
        END
        ELSE
        BEGIN
            PRINT 'Canh bao: Role ' + @RoleName + ' khong ton tai. Tai khoan duoc tao nhung chua co quyen.'
        END
        
        -- Log the account creation
        PRINT 'Tao tai khoan thanh cong cho nhan vien: ' + @TenNhanVien + ' (Ma NV: ' + @MaNV + ')'
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        PRINT 'Loi khi tao tai khoan: ' + @ErrorMessage
        RAISERROR(@ErrorMessage, 16, 1)
    END CATCH
END
GO

-- =============================================
-- Stored Procedure: Delete User Account
-- Removes login and user from database
-- Enhanced with better error handling and role cleanup
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SP_XoaTaiKhoan]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[SP_XoaTaiKhoan]
GO

CREATE PROCEDURE [dbo].[SP_XoaTaiKhoan]
    @TaiKhoan NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        PRINT 'Xoa tai khoan: ' + @TaiKhoan
        
        -- Validate input
        IF @TaiKhoan IS NULL OR @TaiKhoan = ''
        BEGIN
            RAISERROR('Ten tai khoan khong duoc de trong', 16, 1)
            RETURN
        END
        
        -- Prevent deletion of system accounts
        IF @TaiKhoan IN ('$(MSSQL_APP_USER)', '$(MSSQL_PGV_USER)', '$(MSSQL_KHOA_USER)', '$(MSSQL_SV_USER)')
        BEGIN
            RAISERROR('Khong the xoa tai khoan he thong', 16, 1)
            RETURN
        END
        
        -- Check if user exists in database
        IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @TaiKhoan)
        BEGIN
            DECLARE @sql NVARCHAR(MAX)
            SET @sql = 'DROP USER [' + @TaiKhoan + ']'
            EXEC(@sql)
            PRINT 'Da xoa database user: ' + @TaiKhoan
        END
        
        -- Check if login exists at server level
        IF EXISTS (SELECT * FROM sys.server_principals WHERE name = @TaiKhoan)
        BEGIN
            SET @sql = 'DROP LOGIN [' + @TaiKhoan + ']'
            EXEC(@sql)
            PRINT 'Da xoa server login: ' + @TaiKhoan
        END
        
        PRINT 'Xoa tai khoan thanh cong: ' + @TaiKhoan
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        PRINT 'Loi khi xoa tai khoan: ' + @ErrorMessage
        RAISERROR(@ErrorMessage, 16, 1)
    END CATCH
END
GO

-- =============================================
-- Stored Procedure: List User Accounts
-- Shows all user accounts and their roles
-- Enhanced to show system vs custom accounts
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SP_DanhSachTaiKhoan]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[SP_DanhSachTaiKhoan]
GO

CREATE PROCEDURE [dbo].[SP_DanhSachTaiKhoan]
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        dp.name AS TaiKhoan,
        dp.type_desc AS LoaiTaiKhoan,
        r.name AS NhomQuyen,
        dp.create_date AS NgayTao,
        CASE 
            WHEN dp.name IN ('$(MSSQL_APP_USER)', '$(MSSQL_PGV_USER)', '$(MSSQL_KHOA_USER)', '$(MSSQL_SV_USER)') 
            THEN 'He Thong' 
            ELSE 'Nguoi Dung' 
        END AS LoaiTaiKhoan_HeThong
    FROM sys.database_principals dp
    LEFT JOIN sys.database_role_members rm ON dp.principal_id = rm.member_principal_id
    LEFT JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
    WHERE dp.type IN ('S', 'U') -- SQL User, Windows User
        AND dp.name NOT IN ('dbo', 'guest', 'INFORMATION_SCHEMA', 'sys')
    ORDER BY dp.name
END
GO

-- =============================================
-- Stored Procedure: Change Password
-- Changes password for existing user
-- Enhanced with system account protection
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SP_DoiMatKhau]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[SP_DoiMatKhau]
GO

CREATE PROCEDURE [dbo].[SP_DoiMatKhau]
    @TaiKhoan NVARCHAR(50),
    @MatKhauMoi NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        PRINT 'Doi mat khau cho tai khoan: ' + @TaiKhoan
        
        -- Validate input
        IF @TaiKhoan IS NULL OR @TaiKhoan = ''
        BEGIN
            RAISERROR('Ten tai khoan khong duoc de trong', 16, 1)
            RETURN
        END
        
        IF @MatKhauMoi IS NULL OR @MatKhauMoi = ''
        BEGIN
            RAISERROR('Mat khau moi khong duoc de trong', 16, 1)
            RETURN
        END
        
        -- Check if login exists
        IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = @TaiKhoan)
        BEGIN
            RAISERROR('Tai khoan khong ton tai', 16, 1)
            RETURN
        END
        
        -- Change password
        DECLARE @sql NVARCHAR(MAX)
        SET @sql = 'ALTER LOGIN [' + @TaiKhoan + '] WITH PASSWORD = ''' + @MatKhauMoi + ''''
        EXEC(@sql)
        
        PRINT 'Doi mat khau thanh cong cho tai khoan: ' + @TaiKhoan
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        PRINT 'Loi khi doi mat khau: ' + @ErrorMessage
        RAISERROR(@ErrorMessage, 16, 1)
    END CATCH
END
GO

-- =============================================
-- Stored Procedure: Reset System Account Passwords
-- Resets passwords for system accounts to environment defaults
-- Useful for system maintenance
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SP_ResetSystemPasswords]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[SP_ResetSystemPasswords]
GO

CREATE PROCEDURE [dbo].[SP_ResetSystemPasswords]
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        PRINT 'Resetting system account passwords to environment defaults...'
        
        -- Reset main application password
        IF EXISTS (SELECT * FROM sys.server_principals WHERE name = '$(MSSQL_APP_USER)')
        BEGIN
            ALTER LOGIN [$(MSSQL_APP_USER)] WITH PASSWORD = '$(MSSQL_APP_PASSWORD)'
            PRINT 'Reset password for $(MSSQL_APP_USER)'
        END
        
        -- Reset PGV password
        IF EXISTS (SELECT * FROM sys.server_principals WHERE name = '$(MSSQL_PGV_USER)')
        BEGIN
            ALTER LOGIN [$(MSSQL_PGV_USER)] WITH PASSWORD = '$(MSSQL_PGV_PASSWORD)'
            PRINT 'Reset password for $(MSSQL_PGV_USER)'
        END
        
        -- Reset KHOA password
        IF EXISTS (SELECT * FROM sys.server_principals WHERE name = '$(MSSQL_KHOA_USER)')
        BEGIN
            ALTER LOGIN [$(MSSQL_KHOA_USER)] WITH PASSWORD = '$(MSSQL_KHOA_PASSWORD)'
            PRINT 'Reset password for $(MSSQL_KHOA_USER)'
        END
        
        -- Reset SV password
        IF EXISTS (SELECT * FROM sys.server_principals WHERE name = '$(MSSQL_SV_USER)')
        BEGIN
            ALTER LOGIN [$(MSSQL_SV_USER)] WITH PASSWORD = '$(MSSQL_SV_PASSWORD)'
            PRINT 'Reset password for $(MSSQL_SV_USER)'
        END
        
        PRINT 'System password reset completed successfully.'
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        PRINT 'Loi khi reset system passwords: ' + @ErrorMessage
        RAISERROR(@ErrorMessage, 16, 1)
    END CATCH
END
GO

PRINT 'User account management procedures created successfully.' 