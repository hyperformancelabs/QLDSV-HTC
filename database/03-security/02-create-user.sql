-- Map SQL logins to database users and assign roles in QLDSV_HTC

USE [$(DB_NAME)];
GO

-- Drop and create user for main application login
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = '$(MSSQL_APP_USER)')
    DROP USER [$(MSSQL_APP_USER)];
CREATE USER [$(MSSQL_APP_USER)] FOR LOGIN [$(MSSQL_APP_USER)];
GO

-- Drop and create PGV user (admin role)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = '$(MSSQL_PGV_USER)')
    DROP USER [$(MSSQL_PGV_USER)];
CREATE USER [$(MSSQL_PGV_USER)] FOR LOGIN [$(MSSQL_PGV_USER)];
GO

-- Drop and create KHOA user (restricted access)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = '$(MSSQL_KHOA_USER)')
    DROP USER [$(MSSQL_KHOA_USER)];
CREATE USER [$(MSSQL_KHOA_USER)] FOR LOGIN [$(MSSQL_KHOA_USER)];
GO

-- Drop and create SV user (minimal access)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = '$(MSSQL_SV_USER)')
    DROP USER [$(MSSQL_SV_USER)];
CREATE USER [$(MSSQL_SV_USER)] FOR LOGIN [$(MSSQL_SV_USER)];
GO

-- Drop and create SUPERADMIN user
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = '$(MSSQL_SUPERADMIN_USER)')
    DROP USER [$(MSSQL_SUPERADMIN_USER)];
CREATE USER [$(MSSQL_SUPERADMIN_USER)] FOR LOGIN [$(MSSQL_SUPERADMIN_USER)];
GO
