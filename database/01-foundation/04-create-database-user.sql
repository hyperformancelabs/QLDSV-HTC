-- =============================================
-- Database User Creation & Permissions Script  
-- Creates database user and grants necessary permissions
-- =============================================

-- Switch to the target database
USE [$(DB_NAME)]

PRINT 'Setting up database user and permissions...'

-- Create database user for the application login
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '$(MSSQL_APP_USER)')
BEGIN
    CREATE USER [$(MSSQL_APP_USER)] FOR LOGIN [$(MSSQL_APP_USER)]
    PRINT 'Database user [$(MSSQL_APP_USER)] created successfully.'
END
ELSE
BEGIN
    PRINT 'Database user [$(MSSQL_APP_USER)] already exists.'
END

-- Grant necessary permissions to the application user
PRINT 'Granting permissions to application user...'

-- Basic connection permission
GRANT CONNECT TO [$(MSSQL_APP_USER)]

-- Data manipulation permissions
GRANT SELECT, INSERT, UPDATE, DELETE TO [$(MSSQL_APP_USER)]

-- Stored procedure execution permission
GRANT EXECUTE TO [$(MSSQL_APP_USER)]

-- View definition permission (for debugging)
GRANT VIEW DEFINITION TO [$(MSSQL_APP_USER)]

PRINT 'Permissions granted successfully to [$(MSSQL_APP_USER)].'
PRINT 'Database user setup complete.' 