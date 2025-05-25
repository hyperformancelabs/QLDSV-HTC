-- =============================================
-- QLDSV-HTC Security Cleanup Script
-- File: 03-security/01-drop-users-roles.sql
-- Purpose: Drop existing users and roles for clean setup
-- =============================================

USE QLDSV_HTC;
GO

PRINT '🗑️ Cleaning up existing security objects...';

-- =============================================
-- Drop Database Users
-- =============================================

DECLARE @users TABLE (user_name NVARCHAR(128));
INSERT INTO @users VALUES 
    ('qldsv_app'),
    ('pgv_user'),
    ('khoa_user'),
    ('sv_user');

DECLARE @user_name NVARCHAR(128);
DECLARE user_cursor CURSOR FOR SELECT user_name FROM @users;

OPEN user_cursor;
FETCH NEXT FROM user_cursor INTO @user_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @user_name AND type = 'S')
    BEGIN
        -- Remove from all roles first
        DECLARE @role_name NVARCHAR(128);
        DECLARE role_cursor CURSOR FOR 
            SELECT r.name 
            FROM sys.database_principals r
            INNER JOIN sys.database_role_members rm ON r.principal_id = rm.role_principal_id
            INNER JOIN sys.database_principals u ON rm.member_principal_id = u.principal_id
            WHERE u.name = @user_name;
        
        OPEN role_cursor;
        FETCH NEXT FROM role_cursor INTO @role_name;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC sp_droprolemember @role_name, @user_name;
            FETCH NEXT FROM role_cursor INTO @role_name;
        END
        
        CLOSE role_cursor;
        DEALLOCATE role_cursor;
        
        -- Drop the user
        EXEC('DROP USER [' + @user_name + ']');
        PRINT '🗑️ User ' + @user_name + ' dropped';
    END
    FETCH NEXT FROM user_cursor INTO @user_name;
END

CLOSE user_cursor;
DEALLOCATE user_cursor;

-- =============================================
-- Drop Custom Roles
-- =============================================

DECLARE @roles TABLE (role_name NVARCHAR(128));
INSERT INTO @roles VALUES 
    ('PGV'),
    ('KHOA'),
    ('SV');

DECLARE role_cursor2 CURSOR FOR SELECT role_name FROM @roles;

OPEN role_cursor2;
FETCH NEXT FROM role_cursor2 INTO @role_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @role_name AND type = 'R')
    BEGIN
        EXEC('DROP ROLE [' + @role_name + ']');
        PRINT '🗑️ Role ' + @role_name + ' dropped';
    END
    FETCH NEXT FROM role_cursor2 INTO @role_name;
END

CLOSE role_cursor2;
DEALLOCATE role_cursor2;

PRINT '✅ Security cleanup completed';
GO 