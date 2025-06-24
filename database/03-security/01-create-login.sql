-- Create SQL Server Logins for QLDSV_HTC roles: PGV, KHOA, SV

USE [master];
GO

-- Drop and recreate main application login
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = '$(MSSQL_APP_USER)')
    DROP LOGIN [$(MSSQL_APP_USER)];
CREATE LOGIN [$(MSSQL_APP_USER)] WITH PASSWORD = '$(MSSQL_APP_PASSWORD)', CHECK_POLICY = OFF;
GO

-- Drop and recreate PGV login (full administrative access)
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = '$(MSSQL_PGV_USER)')
    DROP LOGIN [$(MSSQL_PGV_USER)];
CREATE LOGIN [$(MSSQL_PGV_USER)] WITH PASSWORD = '$(MSSQL_PGV_PASSWORD)', CHECK_POLICY = OFF;
GO

-- Drop and recreate KHOA login (restricted access)
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = '$(MSSQL_KHOA_USER)')
    DROP LOGIN [$(MSSQL_KHOA_USER)];
CREATE LOGIN [$(MSSQL_KHOA_USER)] WITH PASSWORD = '$(MSSQL_KHOA_PASSWORD)', CHECK_POLICY = OFF;
GO

-- Drop and recreate SV login (minimal access)
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = '$(MSSQL_SV_USER)')
    DROP LOGIN [$(MSSQL_SV_USER)];
CREATE LOGIN [$(MSSQL_SV_USER)] WITH PASSWORD = '$(MSSQL_SV_PASSWORD)', CHECK_POLICY = OFF;
GO

-- Drop and recreate SUPERADMIN login (for high-privilege operations)
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = '$(MSSQL_SUPERADMIN_USER)')
    DROP LOGIN [$(MSSQL_SUPERADMIN_USER)];
CREATE LOGIN [$(MSSQL_SUPERADMIN_USER)] WITH PASSWORD = '$(MSSQL_SUPERADMIN_PASSWORD)', CHECK_POLICY = OFF;
GO
