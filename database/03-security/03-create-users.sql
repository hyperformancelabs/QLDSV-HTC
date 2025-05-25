-- =============================================
-- QLDSV-HTC Users Creation Script
-- File: 03-security/03-create-users.sql
-- Purpose: Create database users and assign roles
-- =============================================

USE QLDSV_HTC;
GO

PRINT '👥 Creating database users for QLDSV-HTC...';

-- =============================================
-- Create Database Users
-- =============================================

-- Application User (for backend API)
CREATE USER [qldsv_app] FOR LOGIN [qldsv_app];
PRINT '✅ User [qldsv_app] created - Application Backend';

-- PGV User (Phòng Giáo Vụ)
CREATE USER [pgv_user] FOR LOGIN [pgv_user];
PRINT '✅ User [pgv_user] created - Phòng Giáo Vụ';

-- KHOA User
CREATE USER [khoa_user] FOR LOGIN [khoa_user];
PRINT '✅ User [khoa_user] created - Khoa';

-- SV User (Sinh Viên)
CREATE USER [sv_user] FOR LOGIN [sv];
PRINT '✅ User [sv_user] created - Sinh Viên';

-- =============================================
-- Assign Users to Roles
-- =============================================

PRINT '🔗 Assigning users to roles...';

-- PGV: Toàn quyền (db_owner + custom role)
ALTER ROLE [db_owner] ADD MEMBER [pgv_user];
ALTER ROLE [PGV] ADD MEMBER [pgv_user];
PRINT '✅ pgv_user assigned to PGV role with full access';

-- Application Backend: Quyền cần thiết cho FastAPI
ALTER ROLE [db_datareader] ADD MEMBER [qldsv_app];
ALTER ROLE [db_datawriter] ADD MEMBER [qldsv_app];
ALTER ROLE [db_ddladmin] ADD MEMBER [qldsv_app];
PRINT '✅ qldsv_app assigned necessary permissions for backend';

-- KHOA: Quyền đọc + custom role
ALTER ROLE [db_datareader] ADD MEMBER [khoa_user];
ALTER ROLE [KHOA] ADD MEMBER [khoa_user];
PRINT '✅ khoa_user assigned to KHOA role with limited access';

-- SV: Quyền đọc + custom role
ALTER ROLE [db_datareader] ADD MEMBER [sv_user];
ALTER ROLE [SV] ADD MEMBER [sv_user];
PRINT '✅ sv_user assigned to SV role with read-only access';

PRINT '👥 All users created and assigned to roles successfully';
GO 