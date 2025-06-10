-- =============================================
-- Application Login Creation Script
-- Creates main application login and role-specific logins for database access
-- Based on QLDSV-HTC requirements: PGV, KHOA, SV roles
-- =============================================

-- Create main application user if it doesn't exist
PRINT 'Setting up main application login...'

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = '$(MSSQL_APP_USER)')
BEGIN
    CREATE LOGIN [$(MSSQL_APP_USER)] WITH PASSWORD = '$(MSSQL_APP_PASSWORD)'
    PRINT 'Main application login [$(MSSQL_APP_USER)] created successfully.'
END
ELSE
BEGIN
    PRINT 'Main application login [$(MSSQL_APP_USER)] already exists.'
    
    -- Update password in case it changed
    ALTER LOGIN [$(MSSQL_APP_USER)] WITH PASSWORD = '$(MSSQL_APP_PASSWORD)'
    PRINT 'Main application login password updated.'
END

-- Create PGV (Phòng Giáo Vụ) login - Full administrative access
PRINT 'Setting up PGV login...'
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = '$(MSSQL_PGV_USER)')
BEGIN
    CREATE LOGIN [$(MSSQL_PGV_USER)] WITH PASSWORD = '$(MSSQL_PGV_PASSWORD)'
    PRINT 'PGV login [$(MSSQL_PGV_USER)] created successfully.'
END
ELSE
BEGIN
    PRINT 'PGV login [$(MSSQL_PGV_USER)] already exists.'
    ALTER LOGIN [$(MSSQL_PGV_USER)] WITH PASSWORD = '$(MSSQL_PGV_PASSWORD)'
    PRINT 'PGV login password updated.'
END

-- Create KHOA login - Limited access (no Khoa, Lop, GiangVien, SinhVien, LopTinChi management)
PRINT 'Setting up KHOA login...'
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = '$(MSSQL_KHOA_USER)')
BEGIN
    CREATE LOGIN [$(MSSQL_KHOA_USER)] WITH PASSWORD = '$(MSSQL_KHOA_PASSWORD)'
    PRINT 'KHOA login [$(MSSQL_KHOA_USER)] created successfully.'
END
ELSE
BEGIN
    PRINT 'KHOA login [$(MSSQL_KHOA_USER)] already exists.'
    ALTER LOGIN [$(MSSQL_KHOA_USER)] WITH PASSWORD = '$(MSSQL_KHOA_PASSWORD)'
    PRINT 'KHOA login password updated.'
END

-- Create SV (Sinh Viên) login - Very limited access (registration and grade viewing only)
PRINT 'Setting up SV login...'
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = '$(MSSQL_SV_USER)')
BEGIN
    CREATE LOGIN [$(MSSQL_SV_USER)] WITH PASSWORD = '$(MSSQL_SV_PASSWORD)'
    PRINT 'SV login [$(MSSQL_SV_USER)] created successfully.'
END
ELSE
BEGIN
    PRINT 'SV login [$(MSSQL_SV_USER)] already exists.'
    ALTER LOGIN [$(MSSQL_SV_USER)] WITH PASSWORD = '$(MSSQL_SV_PASSWORD)'
    PRINT 'SV login password updated.'
END

PRINT 'All application logins setup complete.' 