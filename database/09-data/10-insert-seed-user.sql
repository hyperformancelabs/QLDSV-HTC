-- ===============================================
-- QLDSV-HTC Database Data
-- File: 10-insert-seed-user.sql
-- Description: Tạo tài khoản cho GV001 (PGV) và GV002 (KHOA)
-- ===============================================

USE [$(DB_NAME)];
GO

-- Sau khi trở lại DB ứng dụng, xóa USER nếu tồn tại.

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'GV002')
BEGIN
    DROP USER [GV002];
END
GO

-- Xóa login và user cũ nếu tồn tại
-- Xóa user trước, sau đó xóa login
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'GV001')
BEGIN
    DROP USER [GV001];
END
GO

-- Phải thực thi DROP/CREATE LOGIN ở cấp độ server (master)
USE [master];
GO

-- (Không DROP LOGIN để tránh lỗi trên một số bản SQL Server Linux)
GO

-- Trở lại database ứng dụng
USE [$(DB_NAME)];
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
