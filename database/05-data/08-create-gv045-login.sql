-- ===============================================
-- QLDSV-HTC Create GV045 SQL Server Login
-- File: 00-create-gv045-login.sql
-- Description: Create SQL Server login for GV045 (master database level)
-- Location: 05-data (seed data)
-- ===============================================

USE [master];
GO

-- Drop existing login if exists (for reset scenarios)
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'GV045')
BEGIN
    DROP LOGIN [GV045];
    PRINT 'Dropped existing GV045 login for reset';
END

-- Create login for GV045 in master database
CREATE LOGIN [GV045] WITH 
    PASSWORD = 'GV045pass123#', 
    CHECK_POLICY = OFF, 
    DEFAULT_DATABASE = [$(DB_NAME)];

PRINT 'Created GV045 SQL Server login with password: GV045pass123#';
PRINT 'Login can be used for SQL Server authentication';
PRINT 'GV045 SQL Server login setup completed';
GO 