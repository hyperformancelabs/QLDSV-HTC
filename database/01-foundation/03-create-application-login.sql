-- =============================================
-- Application Login Creation Script
-- Creates the application login for database access
-- =============================================

-- Create application user if it doesn't exist
PRINT 'Setting up application login...'

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = '$(MSSQL_APP_USER)')
BEGIN
    CREATE LOGIN [$(MSSQL_APP_USER)] WITH PASSWORD = '$(MSSQL_APP_PASSWORD)'
    PRINT 'Application login [$(MSSQL_APP_USER)] created successfully.'
END
ELSE
BEGIN
    PRINT 'Application login [$(MSSQL_APP_USER)] already exists.'
    
    -- Update password in case it changed
    ALTER LOGIN [$(MSSQL_APP_USER)] WITH PASSWORD = '$(MSSQL_APP_PASSWORD)'
    PRINT 'Application login password updated.'
END

PRINT 'Application login setup complete.' 