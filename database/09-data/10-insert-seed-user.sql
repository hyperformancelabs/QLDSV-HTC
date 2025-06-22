-- ===============================================
-- QLDSV-HTC Database Data
-- File: 10-insert-seed-user.sql
-- Description: Tạo tài khoản cho GV001 (PGV) và GV002 (KHOA)
-- ===============================================

USE [$(DB_NAME)];
GO

-- Xóa login và user cũ nếu tồn tại
-- Xóa user trước, sau đó xóa login
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'GV001')
BEGIN
    DROP USER [GV001];
END
GO

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'GV001_LOGIN')
BEGIN
    DROP LOGIN [GV001_LOGIN];
END
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'GV002')
BEGIN
    DROP USER [GV002];
END
GO

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'GV002_LOGIN')
BEGIN
    DROP LOGIN [GV002_LOGIN];
END
GO

-- Tạo tài khoản cho GV001 (Nguyễn Duy Phương) với role PGV
EXEC dbo.sp_TaoTaiKhoan 
    @LOGINNAME = 'GV001_LOGIN',
    @PASSWORD = '123456',
    @USERID = 'GV001',
    @ROLE = 'pgv_role';
GO

-- Tạo tài khoản cho GV002 (Nguyễn Mạnh Hùng) với role KHOA
EXEC dbo.sp_TaoTaiKhoan 
    @LOGINNAME = 'GV002_LOGIN',
    @PASSWORD = '123456',
    @USERID = 'GV002',
    @ROLE = 'khoa_role';
GO
