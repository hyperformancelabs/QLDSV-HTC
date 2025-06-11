-- =============================================
-- Database Creation Script
-- Creates the main QLDSV_HTC database with optimal settings
-- =============================================

USE [master];
GO

-- Make the script idempotent - handle existing database
IF EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = '$(DB_NAME)')
BEGIN
    PRINT 'Database $(DB_NAME) already exists.'
    PRINT 'Dropping existing database...'
    
    -- Set database to single user mode to disconnect other users
    ALTER DATABASE [$(DB_NAME)] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    
    -- Drop the database
    DROP DATABASE [$(DB_NAME)];
    
    PRINT 'Database $(DB_NAME) dropped successfully.'
END

-- Create the database
PRINT 'Creating database $(DB_NAME)...'
CREATE DATABASE [$(DB_NAME)]

PRINT 'Database $(DB_NAME) created successfully.' 