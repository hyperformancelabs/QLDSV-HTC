-- =============================================
-- Database Configuration Script
-- Sets optimal database options for performance and compatibility
-- =============================================

-- Switch to the newly created database
USE [$(DB_NAME)]

PRINT 'Setting database options...'

-- Set recommended database options for performance and ANSI compliance
ALTER DATABASE [$(DB_NAME)] SET ANSI_NULL_DEFAULT ON
ALTER DATABASE [$(DB_NAME)] SET ANSI_NULLS ON
ALTER DATABASE [$(DB_NAME)] SET ANSI_PADDING ON
ALTER DATABASE [$(DB_NAME)] SET ANSI_WARNINGS ON
ALTER DATABASE [$(DB_NAME)] SET ARITHABORT ON
ALTER DATABASE [$(DB_NAME)] SET CONCAT_NULL_YIELDS_NULL ON
ALTER DATABASE [$(DB_NAME)] SET NUMERIC_ROUNDABORT OFF
ALTER DATABASE [$(DB_NAME)] SET QUOTED_IDENTIFIER ON

-- Additional performance settings
ALTER DATABASE [$(DB_NAME)] SET AUTO_CREATE_STATISTICS ON
ALTER DATABASE [$(DB_NAME)] SET AUTO_UPDATE_STATISTICS ON
ALTER DATABASE [$(DB_NAME)] SET AUTO_UPDATE_STATISTICS_ASYNC OFF

PRINT 'Database options configured successfully.' 