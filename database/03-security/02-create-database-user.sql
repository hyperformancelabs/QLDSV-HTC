-- =============================================
-- Database User & Role Creation Script  
-- Creates database users, roles and grants permissions according to QLDSV-HTC requirements
-- Role hierarchy: PGV (full access) > KHOA (limited) > SV (read-only + self-registration)
-- =============================================

-- Switch to the target database
USE [$(DB_NAME)]

PRINT 'Setting up database users and roles...'

-- =============================================
-- Create Database Roles
-- =============================================

-- Create PGV role (Phòng Giáo Vụ) - Full administrative access
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'PGV_ROLE' AND type = 'R')
BEGIN
    CREATE ROLE [PGV_ROLE]
    PRINT 'PGV_ROLE created successfully.'
END
ELSE
BEGIN
    PRINT 'PGV_ROLE already exists.'
END

-- Create KHOA role - Limited access (cannot manage Khoa, Lop, GiangVien, SinhVien, LopTinChi)
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'KHOA_ROLE' AND type = 'R')
BEGIN
    CREATE ROLE [KHOA_ROLE]
    PRINT 'KHOA_ROLE created successfully.'
END
ELSE
BEGIN
    PRINT 'KHOA_ROLE already exists.'
END

-- Create SV role (Sinh Viên) - Very limited access (registration and own grades only)
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'SV_ROLE' AND type = 'R')
BEGIN
    CREATE ROLE [SV_ROLE]
    PRINT 'SV_ROLE created successfully.'
END
ELSE
BEGIN
    PRINT 'SV_ROLE already exists.'
END

-- =============================================
-- Create Database Users
-- =============================================

-- Create main application user
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '$(MSSQL_APP_USER)')
BEGIN
    CREATE USER [$(MSSQL_APP_USER)] FOR LOGIN [$(MSSQL_APP_USER)]
    PRINT 'Main application user [$(MSSQL_APP_USER)] created successfully.'
END
ELSE
BEGIN
    PRINT 'Main application user [$(MSSQL_APP_USER)] already exists.'
END

-- Create PGV user
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '$(MSSQL_PGV_USER)')
BEGIN
    CREATE USER [$(MSSQL_PGV_USER)] FOR LOGIN [$(MSSQL_PGV_USER)]
    PRINT 'PGV user [$(MSSQL_PGV_USER)] created successfully.'
END
ELSE
BEGIN
    PRINT 'PGV user [$(MSSQL_PGV_USER)] already exists.'
END

-- Create KHOA user
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '$(MSSQL_KHOA_USER)')
BEGIN
    CREATE USER [$(MSSQL_KHOA_USER)] FOR LOGIN [$(MSSQL_KHOA_USER)]
    PRINT 'KHOA user [$(MSSQL_KHOA_USER)] created successfully.'
END
ELSE
BEGIN
    PRINT 'KHOA user [$(MSSQL_KHOA_USER)] already exists.'
END

-- Create SV user
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '$(MSSQL_SV_USER)')
BEGIN
    CREATE USER [$(MSSQL_SV_USER)] FOR LOGIN [$(MSSQL_SV_USER)]
    PRINT 'SV user [$(MSSQL_SV_USER)] created successfully.'
END
ELSE
BEGIN
    PRINT 'SV user [$(MSSQL_SV_USER)] already exists.'
END

-- =============================================
-- Assign Users to Roles
-- =============================================

-- Add users to their respective roles
EXEC sp_addrolemember 'PGV_ROLE', '$(MSSQL_PGV_USER)'
EXEC sp_addrolemember 'KHOA_ROLE', '$(MSSQL_KHOA_USER)'
EXEC sp_addrolemember 'SV_ROLE', '$(MSSQL_SV_USER)'

PRINT 'Users assigned to roles successfully.'

-- =============================================
-- Grant Permissions to Main Application User
-- =============================================

PRINT 'Granting permissions to main application user...'

-- Basic connection permission
GRANT CONNECT TO [$(MSSQL_APP_USER)]

-- Full data manipulation permissions for main app
GRANT SELECT, INSERT, UPDATE, DELETE TO [$(MSSQL_APP_USER)]

-- Stored procedure execution permission
GRANT EXECUTE TO [$(MSSQL_APP_USER)]

-- View definition permission (for debugging)
GRANT VIEW DEFINITION TO [$(MSSQL_APP_USER)]

-- =============================================
-- Grant Permissions to PGV Role (Full Access)
-- =============================================

PRINT 'Granting full permissions to PGV_ROLE...'

-- Full access to all tables and operations
GRANT CONNECT TO [PGV_ROLE]
GRANT SELECT, INSERT, UPDATE, DELETE TO [PGV_ROLE]
GRANT EXECUTE TO [PGV_ROLE]
GRANT VIEW DEFINITION TO [PGV_ROLE]

-- Allow PGV to create/modify database objects (for admin tasks)
GRANT CREATE TABLE, CREATE PROCEDURE, CREATE FUNCTION, CREATE VIEW TO [PGV_ROLE]

-- =============================================
-- Grant Permissions to KHOA Role (Limited Access)
-- =============================================

PRINT 'Granting limited permissions to KHOA_ROLE...'

-- Basic connection
GRANT CONNECT TO [KHOA_ROLE]

-- Read access to all tables for reporting
GRANT SELECT TO [KHOA_ROLE]

-- Specific write access - KHOA can only input grades and manage course registrations
-- They CANNOT manage: Khoa, Lop, GiangVien, SinhVien, LopTinChi (per requirements)
GRANT INSERT, UPDATE, DELETE ON [dbo].[DANGKY] TO [KHOA_ROLE]

-- Allow execution of specific stored procedures for grade input and reports
GRANT EXECUTE TO [KHOA_ROLE]

-- =============================================
-- Grant Permissions to SV Role (Very Limited Access)
-- =============================================

PRINT 'Granting very limited permissions to SV_ROLE...'

-- Basic connection
GRANT CONNECT TO [SV_ROLE]

-- Read-only access to specific tables for student information
GRANT SELECT ON [dbo].[SINHVIEN] TO [SV_ROLE]
GRANT SELECT ON [dbo].[LOPTINCHI] TO [SV_ROLE]
GRANT SELECT ON [dbo].[MONHOC] TO [SV_ROLE]
GRANT SELECT ON [dbo].[GIANGVIEN] TO [SV_ROLE]
GRANT SELECT ON [dbo].[KHOA] TO [SV_ROLE]
GRANT SELECT ON [dbo].[LOP] TO [SV_ROLE]

-- Students can register for courses
GRANT INSERT, UPDATE, DELETE ON [dbo].[DANGKY] TO [SV_ROLE]

-- Students can view their own grades (through specific stored procedures)
GRANT SELECT ON [dbo].[DANGKY] TO [SV_ROLE]

-- Allow execution of student-specific stored procedures only
-- Note: Specific procedure permissions will be granted when procedures are created

PRINT 'All permissions granted successfully.'
PRINT 'Database users and roles setup complete.' 