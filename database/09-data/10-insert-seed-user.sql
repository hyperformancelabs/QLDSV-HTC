-- ===============================================
-- QLDSV-HTC Database Data
-- File: 10-insert-seed-user.sql
-- Description: Tạo tài khoản cho GV001 (PGV) và GV002 (KHOA)
-- ===============================================

USE [$(DB_NAME)];
GO

-- Tạo login cho GV001 (Nguyễn Duy Phương) với role PGV
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'GV001_LOGIN')
BEGIN
    CREATE LOGIN [GV001_LOGIN] WITH PASSWORD = '123456', CHECK_POLICY = OFF;
END
GO

-- Tạo user và cấp quyền nếu chưa tồn tại
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'GV001')
BEGIN
    CREATE USER [GV001] FOR LOGIN [GV001_LOGIN];
    ALTER ROLE [pgv_role] ADD MEMBER [GV001];
END
ELSE 
BEGIN
    -- Đảm bảo user có quyền thích hợp
    IF NOT IS_ROLEMEMBER('pgv_role', 'GV001') = 1
    BEGIN
        ALTER ROLE [pgv_role] ADD MEMBER [GV001];
    END
END
GO

-- Tạo login cho GV002 (Nguyễn Mạnh Hùng) với role KHOA
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'GV002_LOGIN')
BEGIN
    CREATE LOGIN [GV002_LOGIN] WITH PASSWORD = '123456', CHECK_POLICY = OFF;
END
GO

-- Tạo user và cấp quyền nếu chưa tồn tại
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'GV002')
BEGIN
    CREATE USER [GV002] FOR LOGIN [GV002_LOGIN];
    ALTER ROLE [khoa_role] ADD MEMBER [GV002];
END
ELSE 
BEGIN
    -- Đảm bảo user có quyền thích hợp
    IF NOT IS_ROLEMEMBER('khoa_role', 'GV002') = 1
    BEGIN
        ALTER ROLE [khoa_role] ADD MEMBER [GV002];
    END
END
GO
