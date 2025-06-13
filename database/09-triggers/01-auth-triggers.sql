-- ===============================================
-- QLDSV-HTC Authentication Triggers
-- File: 01-auth-triggers.sql
-- Description: Triggers for authentication logging
-- ===============================================

USE [$(DB_NAME)];
GO

-- First, create a table to log authentication attempts
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AuthLog]'))
BEGIN
    CREATE TABLE [dbo].[AuthLog](
        [ID] INT IDENTITY(1,1) PRIMARY KEY,
        [UserID] NVARCHAR(50) NOT NULL,
        [UserType] NVARCHAR(20) NOT NULL,
        [LoginTime] DATETIME NOT NULL DEFAULT GETDATE(),
        [Status] NVARCHAR(20) NOT NULL,
        [IPAddress] NVARCHAR(50) NULL,
        [Details] NVARCHAR(MAX) NULL
    );
    
    PRINT 'AuthLog table created successfully';
END
GO

-- ===============================================
-- 1. TR_SinhVien_XacThuc_Log - Log authentication attempts
-- ===============================================
CREATE OR ALTER TRIGGER [dbo].[TR_SinhVien_XacThuc_Log]
ON [dbo].[SINHVIEN]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Only log if LastLogin field is updated
    IF UPDATE(PASSWORD)
    BEGIN
        INSERT INTO [dbo].[AuthLog]
        (
            [UserID],
            [UserType],
            [Status],
            [Details]
        )
        SELECT
            i.MASV,
            'SV',
            'PASSWORD_CHANGE',
            'Password changed for student ' + i.MASV
        FROM
            inserted i;
            
        PRINT 'Password change logged for student';
    END
END
GO

PRINT 'Authentication triggers created successfully'; 