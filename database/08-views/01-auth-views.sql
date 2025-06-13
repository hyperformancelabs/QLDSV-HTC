-- ===============================================
-- QLDSV-HTC Authentication Views
-- File: 01-auth-views.sql
-- Description: Views for authentication
-- ===============================================

USE [$(DB_NAME)];
GO

-- ===============================================
-- 1. V_SinhVien_DanhSach - List of active students
-- ===============================================
CREATE OR ALTER VIEW [dbo].[V_SinhVien_DanhSach]
AS
SELECT 
    SV.MASV, 
    SV.HO, 
    SV.TEN, 
    SV.MALOP,
    SV.HO + N' ' + SV.TEN AS HoTen
FROM 
    dbo.SINHVIEN SV
WHERE 
    SV.DANGHIHOC = 0;
GO

-- ===============================================
-- 2. V_SinhVien_ThongTinDayDu - Full student information
-- ===============================================
CREATE OR ALTER VIEW [dbo].[V_SinhVien_ThongTinDayDu]
AS
SELECT 
    SV.MASV, 
    SV.HO, 
    SV.TEN, 
    SV.MALOP, 
    SV.PHAI, 
    SV.NGAYSINH, 
    SV.DIACHI, 
    SV.DANGHIHOC,
    SV.HO + N' ' + SV.TEN AS HoTen,
    L.TENLOP,
    K.TENKHOA
FROM 
    dbo.SINHVIEN SV
    INNER JOIN dbo.LOP L ON SV.MALOP = L.MALOP
    INNER JOIN dbo.KHOA K ON L.MAKHOA = K.MAKHOA;
GO

PRINT 'Authentication views created successfully'; 