-- =============================================
-- QLDSV-HTC Database Foundation Script
-- File: 01-foundation/01-init-database.sql
-- Purpose: Initialize database with DROP/CREATE pattern for development
-- =============================================

USE master;
GO

PRINT '🗑️ Cleaning up existing database...';

-- Drop database if exists (for development/testing)
IF EXISTS (SELECT name FROM sys.databases WHERE name = '$(QLDSV_DB_NAME)')
BEGIN
    -- Force close all connections
    ALTER DATABASE [$(QLDSV_DB_NAME)] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [$(QLDSV_DB_NAME)];
    PRINT '🗑️ Existing database $(QLDSV_DB_NAME) dropped';
END

-- Create database with Vietnamese collation
CREATE DATABASE [$(QLDSV_DB_NAME)]
COLLATE Vietnamese_CI_AS;

PRINT '✅ Database $(QLDSV_DB_NAME) created successfully with Vietnamese collation';

-- Set database options for optimal performance
ALTER DATABASE [$(QLDSV_DB_NAME)] SET RECOVERY FULL;
ALTER DATABASE [$(QLDSV_DB_NAME)] SET AUTO_CLOSE OFF;
ALTER DATABASE [$(QLDSV_DB_NAME)] SET AUTO_SHRINK OFF;
ALTER DATABASE [$(QLDSV_DB_NAME)] SET AUTO_CREATE_STATISTICS ON;
ALTER DATABASE [$(QLDSV_DB_NAME)] SET AUTO_UPDATE_STATISTICS ON;
ALTER DATABASE [$(QLDSV_DB_NAME)] SET AUTO_UPDATE_STATISTICS_ASYNC ON;
ALTER DATABASE [$(QLDSV_DB_NAME)] SET PAGE_VERIFY CHECKSUM;

PRINT '✅ Database configuration completed';
GO 