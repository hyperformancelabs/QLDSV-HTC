-- Create or recreate QLDSV_HTC database

USE [master];
GO

-- Drop and recreate database
IF EXISTS (SELECT name FROM sys.databases WHERE name = '$(DB_NAME)')
BEGIN
    ALTER DATABASE [$(DB_NAME)] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [$(DB_NAME)];
END
GO

-- Create databasez
CREATE DATABASE [$(DB_NAME)]
ON PRIMARY (
    NAME = '$(DB_NAME)_data',
    FILENAME = '/var/opt/mssql/data/$(DB_NAME)_data.mdf',
    SIZE = 20MB,
    MAXSIZE = 500MB,
    FILEGROWTH = 10MB
)
LOG ON (
    NAME = '$(DB_NAME)_log',
    FILENAME = '/var/opt/mssql/data/$(DB_NAME)_log.ldf',
    SIZE = 10MB,
    MAXSIZE = 250MB,
    FILEGROWTH = 5MB
);
GO
