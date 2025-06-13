-- ===============================================
-- QLDSV-HTC Grant Permissions
-- File: 04-grant-permissions.sql
-- Description: Grant permissions to users
-- ===============================================

USE [$(DB_NAME)];
GO

-- ===============================================
-- Grant permissions for sv_user
-- ===============================================
PRINT 'Granting permissions for sv_user...';

-- Grant execute permission on stored procedures
GRANT EXECUTE ON [dbo].[SP_SinhVien_XacThuc] TO [sv_user];
GRANT EXECUTE ON [dbo].[SP_SinhVien_DanhSach] TO [sv_user];
GRANT EXECUTE ON [dbo].[SP_SinhVien_ThongTin] TO [sv_user];

-- Grant select permission on views
GRANT SELECT ON [dbo].[V_SinhVien_DanhSach] TO [sv_user];
GRANT SELECT ON [dbo].[V_SinhVien_ThongTinDayDu] TO [sv_user];

-- Grant execute permission on functions
GRANT EXECUTE ON [dbo].[FN_SinhVien_TenHienThi] TO [sv_user];
GRANT EXECUTE ON [dbo].[FN_SinhVien_KiemTraMatKhau] TO [sv_user];

PRINT 'Permissions granted for sv_user successfully';

-- ===============================================
-- Grant permissions for pgv_user
-- ===============================================
PRINT 'Granting permissions for pgv_user...';

-- Grant execute permission on stored procedures
GRANT EXECUTE ON [dbo].[SP_SinhVien_XacThuc] TO [pgv_user];
GRANT EXECUTE ON [dbo].[SP_SinhVien_DanhSach] TO [pgv_user];
GRANT EXECUTE ON [dbo].[SP_SinhVien_ThongTin] TO [pgv_user];

-- Grant select permission on views
GRANT SELECT ON [dbo].[V_SinhVien_DanhSach] TO [pgv_user];
GRANT SELECT ON [dbo].[V_SinhVien_ThongTinDayDu] TO [pgv_user];

-- Grant execute permission on functions
GRANT EXECUTE ON [dbo].[FN_SinhVien_TenHienThi] TO [pgv_user];
GRANT EXECUTE ON [dbo].[FN_SinhVien_KiemTraMatKhau] TO [pgv_user];

PRINT 'Permissions granted for pgv_user successfully';

-- ===============================================
-- Grant permissions for khoa_user
-- ===============================================
PRINT 'Granting permissions for khoa_user...';

-- Grant execute permission on stored procedures
GRANT EXECUTE ON [dbo].[SP_SinhVien_XacThuc] TO [khoa_user];
GRANT EXECUTE ON [dbo].[SP_SinhVien_DanhSach] TO [khoa_user];
GRANT EXECUTE ON [dbo].[SP_SinhVien_ThongTin] TO [khoa_user];

-- Grant select permission on views
GRANT SELECT ON [dbo].[V_SinhVien_DanhSach] TO [khoa_user];
GRANT SELECT ON [dbo].[V_SinhVien_ThongTinDayDu] TO [khoa_user];

-- Grant execute permission on functions
GRANT EXECUTE ON [dbo].[FN_SinhVien_TenHienThi] TO [khoa_user];
GRANT EXECUTE ON [dbo].[FN_SinhVien_KiemTraMatKhau] TO [khoa_user];

PRINT 'Permissions granted for khoa_user successfully';

-- ===============================================
-- Grant permissions for app_user
-- ===============================================
PRINT 'Granting permissions to app_user...';
GO

-- Grant SELECT, INSERT, UPDATE, DELETE on all tables to app_user
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO [$(MSSQL_APP_USER)];
GO

-- Grant EXECUTE on all stored procedures to app_user
GRANT EXECUTE ON SCHEMA::dbo TO [$(MSSQL_APP_USER)];
GO

-- Grant roles for different user types (these will be applied after login)
PRINT 'Setting up role-based permissions...';
GO

-- Create database roles if they don't exist
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'SinhVienRole' AND type = 'R')
BEGIN
    CREATE ROLE SinhVienRole;
    PRINT 'Created SinhVienRole';
END
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'PGVRole' AND type = 'R')
BEGIN
    CREATE ROLE PGVRole;
    PRINT 'Created PGVRole';
END
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'KhoaRole' AND type = 'R')
BEGIN
    CREATE ROLE KhoaRole;
    PRINT 'Created KhoaRole';
END
GO

-- Map database users to roles
-- Note: These users will be used after authentication with app_user
ALTER ROLE SinhVienRole ADD MEMBER [sv_user];
GO

ALTER ROLE PGVRole ADD MEMBER [pgv_user];
GO

ALTER ROLE KhoaRole ADD MEMBER [khoa_user];
GO

-- Grant permissions to SinhVienRole
PRINT 'Granting permissions to SinhVienRole...';
GO

-- SinhVien can view their own information and grades
GRANT SELECT ON V_SinhVien_ThongTin TO SinhVienRole;
GRANT EXECUTE ON SP_SinhVien_ThongTin TO SinhVienRole;
GRANT EXECUTE ON SP_SinhVien_XacThuc TO SinhVienRole;
-- Add more permissions as needed for student operations
GO

-- Grant permissions to PGVRole (Phòng Giáo Vụ)
PRINT 'Granting permissions to PGVRole...';
GO

-- PGV can manage all student data
GRANT SELECT, INSERT, UPDATE, DELETE ON SinhVien TO PGVRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Lop TO PGVRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON KetQuaHocTap TO PGVRole;
GRANT EXECUTE ON SP_SinhVien_DanhSach TO PGVRole;
-- Add more permissions as needed for PGV operations
GO

-- Grant permissions to KhoaRole
PRINT 'Granting permissions to KhoaRole...';
GO

-- Khoa can view and update specific data
GRANT SELECT ON SinhVien TO KhoaRole;
GRANT SELECT ON Lop TO KhoaRole;
GRANT SELECT, INSERT, UPDATE ON KetQuaHocTap TO KhoaRole;
GRANT EXECUTE ON SP_SinhVien_DanhSach TO KhoaRole;
-- Add more permissions as needed for Khoa operations
GO

-- Grant execute permissions on specific stored procedures to all roles
PRINT 'Granting common procedure permissions...';
GO

GRANT EXECUTE ON [dbo].[SP_SinhVien_DanhSach] TO SinhVienRole, PGVRole, KhoaRole;
GO

PRINT 'All permissions granted successfully.';
GO 