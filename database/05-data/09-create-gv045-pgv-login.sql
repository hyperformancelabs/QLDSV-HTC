-- ===============================================
-- QLDSV-HTC Create GV045 Database User and PGV Role
-- File: 08-create-gv045-pgv-login.sql
-- Description: Create database user for GV045 and grant PGV role
-- Note: SQL Server login is created in 01-foundation/03-create-gv045-login.sql
-- ===============================================

USE [$(DB_NAME)];
GO

-- Verify GV045 exists in GIANGVIEN table
IF EXISTS (SELECT * FROM GIANGVIEN WHERE MAGV = 'GV045')
BEGIN
    PRINT 'GV045 teacher record found';
END
ELSE
BEGIN
    PRINT 'ERROR: GV045 teacher record not found';
    RETURN;
END

-- Create database user for the login (login must already exist)
-- Drop existing user if exists (for reset scenarios)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'GV045')
BEGIN
    -- Remove from roles first
    IF IS_ROLEMEMBER('PGV_ROLE', 'GV045') = 1
    BEGIN
        EXEC sp_droprolemember 'PGV_ROLE', 'GV045';
        PRINT 'Removed GV045 from PGV_ROLE';
    END
    
    DROP USER [GV045];
    PRINT 'Dropped existing GV045 database user for reset';
END

-- Create database user for the login
CREATE USER [GV045] FOR LOGIN [GV045];
PRINT 'Created GV045 database user';

-- Add user to PGV_ROLE
EXEC sp_addrolemember 'PGV_ROLE', 'GV045';
PRINT 'Added GV045 to PGV_ROLE - now has PGV permissions';

-- Verify the setup
SELECT 
    sp.name AS LoginName,
    sp.type_desc AS LoginType,
    sp.create_date AS LoginCreated,
    dp.name AS DatabaseUser,
    r.name AS RoleName
FROM sys.server_principals sp
LEFT JOIN sys.database_principals dp ON sp.name = dp.name
LEFT JOIN sys.database_role_members rm ON dp.principal_id = rm.member_principal_id
LEFT JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
WHERE sp.name = 'GV045';

PRINT 'GV045 PGV login setup completed successfully';
PRINT 'Login credentials: GV045 / GV045pass123#';
PRINT 'GV045 now has PGV (Phòng Giáo Vụ) role permissions';
GO 