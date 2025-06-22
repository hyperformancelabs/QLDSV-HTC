-- Create roles for QLDSV_HTC database

USE [$(DB_NAME)];
GO

-- Drop and create roles
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'app_role')
    DROP ROLE app_role;
CREATE ROLE app_role;
-- Grant operational access for app backend
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::dbo TO app_role;
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'pgv_role')
    DROP ROLE pgv_role;
CREATE ROLE pgv_role;
-- Grant full rights for PGV
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::dbo TO pgv_role;
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'khoa_role')
    DROP ROLE khoa_role;
CREATE ROLE khoa_role;
-- Grant read-only to KHOA
GRANT SELECT ON SCHEMA::dbo TO khoa_role;
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'sv_role')
    DROP ROLE sv_role;
CREATE ROLE sv_role;
-- Grant minimal permissions for SV
GRANT SELECT ON dbo.MONHOC TO sv_role;
GRANT SELECT ON dbo.LOPTINCHI TO sv_role;
GRANT SELECT ON dbo.DANGKY TO sv_role;
-- Grant EXECUTE on relevant SPs (later)
GO


-- Assign users to roles
ALTER ROLE pgv_role ADD MEMBER [$(MSSQL_PGV_USER)];
ALTER ROLE khoa_role ADD MEMBER [$(MSSQL_KHOA_USER)];
ALTER ROLE sv_role ADD MEMBER [$(MSSQL_SV_USER)];
ALTER ROLE app_role ADD MEMBER [$(MSSQL_APP_USER)];
GO
