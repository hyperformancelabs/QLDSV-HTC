-- ===============================================
-- QLDSV-HTC Authentication Functions
-- File: 01-auth-functions.sql
-- Description: User-defined functions for authentication
-- ===============================================

USE [$(DB_NAME)];
GO

-- ===============================================
-- 1. FN_SinhVien_TenHienThi - Generate display name
-- ===============================================
CREATE OR ALTER FUNCTION [dbo].[FN_SinhVien_TenHienThi]
(
    @HO NVARCHAR(50),
    @TEN NVARCHAR(10),
    @COUNT INT
)
RETURNS NVARCHAR(100)
AS
BEGIN
    DECLARE @TenHienThi NVARCHAR(100);
    
    SET @TenHienThi = @HO + N' ' + @TEN;
    
    IF @COUNT > 1
        SET @TenHienThi = @TenHienThi + N' ' + CAST(@COUNT AS NVARCHAR);
        
    RETURN @TenHienThi;
END
GO

-- ===============================================
-- 2. FN_SinhVien_KiemTraMatKhau - Check password
-- ===============================================
CREATE OR ALTER FUNCTION [dbo].[FN_SinhVien_KiemTraMatKhau]
(
    @MASV NCHAR(10),
    @PASSWORD NVARCHAR(40)
)
RETURNS BIT
AS
BEGIN
    DECLARE @Result BIT = 0;
    
    IF EXISTS (
        SELECT 1
        FROM dbo.SINHVIEN SV
        WHERE SV.MASV = @MASV 
          AND SV.PASSWORD = @PASSWORD
          AND SV.DANGHIHOC = 0
    )
        SET @Result = 1;
    
    RETURN @Result;
END
GO

PRINT 'Authentication functions created successfully'; 