-- =============================================
-- QLDSV-HTC SQL Server Logins Management Script
-- File: 01-foundation/02-create-logins.sql
-- Purpose: Create SQL Server logins with DROP/CREATE pattern
-- =============================================

USE master;
GO

PRINT '🗑️ Cleaning up existing logins...';

-- Drop existing logins if they exist
DECLARE @logins TABLE (login_name NVARCHAR(128));
INSERT INTO @logins VALUES 
    ('$(QLDSV_APP_USER)'),
    ('pgv_user'),
    ('khoa_user'),
    ('sv');

DECLARE @login_name NVARCHAR(128);
DECLARE login_cursor CURSOR FOR SELECT login_name FROM @logins;

OPEN login_cursor;
FETCH NEXT FROM login_cursor INTO @login_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF EXISTS (SELECT name FROM sys.server_principals WHERE name = @login_name)
    BEGIN
        EXEC('DROP LOGIN [' + @login_name + ']');
        PRINT '🗑️ Login ' + @login_name + ' dropped';
    END
    FETCH NEXT FROM login_cursor INTO @login_name;
END

CLOSE login_cursor;
DEALLOCATE login_cursor;

PRINT '🔧 Creating new logins...';

-- Create Application Login (for backend API)
CREATE LOGIN [$(QLDSV_APP_USER)] WITH PASSWORD = '$(QLDSV_APP_PASSWORD)';
PRINT '✅ Login $(QLDSV_APP_USER) created successfully';

-- Create PGV Login (Phòng Giáo Vụ - Full access)
CREATE LOGIN [pgv_user] WITH PASSWORD = 'PGV@2024!';
PRINT '✅ Login pgv_user created successfully';

-- Create KHOA Login (Khoa - Limited access)
CREATE LOGIN [khoa_user] WITH PASSWORD = 'Khoa@2024!';
PRINT '✅ Login khoa_user created successfully';

-- Create SV Login (Sinh Viên - Registration only)
CREATE LOGIN [sv] WITH PASSWORD = 'SinhVien@2024';
PRINT '✅ Login sv created successfully';

PRINT '✅ All logins created successfully';
GO 