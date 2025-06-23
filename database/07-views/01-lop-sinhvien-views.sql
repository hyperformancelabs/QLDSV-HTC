/*===========================================================
  File        : 01-lop-sinhvien-views.sql
  Description : Các VIEW hỗ trợ hiển thị danh mục LOP và SINHVIEN
===========================================================*/

USE [$(DB_NAME)];
GO

/*===========================================================
  V_LOP_INFO
  Trả về thông tin lớp và số sinh viên đang theo học (DangNghiHoc = 0)
===========================================================*/
CREATE OR ALTER VIEW dbo.V_LOP_INFO
AS
SELECT  l.MALOP,
        l.TENLOP,
        l.KHOAHOC,
        l.MAKHOA,
        (SELECT COUNT(*)
         FROM   dbo.SINHVIEN sv WITH (NOLOCK)
         WHERE  sv.MALOP = l.MALOP
           AND  sv.DANGHIHOC = 0) AS SOLUONGSV
FROM    dbo.LOP l WITH (NOLOCK);
GO

/*===========================================================
  V_SINHVIEN_INFO
  Trả về thông tin sinh viên kèm tên lớp (JOIN LOP)
===========================================================*/
CREATE OR ALTER VIEW dbo.V_SINHVIEN_INFO
AS
SELECT  sv.MASV,
        sv.HO,
        sv.TEN,
        sv.PHAI,
        sv.NGAYSINH,
        sv.DIACHI,
        sv.DANGHIHOC,
        sv.MALOP,
        l.TENLOP
FROM    dbo.SINHVIEN sv WITH (NOLOCK)
JOIN    dbo.LOP l ON l.MALOP = sv.MALOP;
GO

/*===========================================================
  V_LOP_WithStudentCount
  Purpose   : Lấy danh sách lớp kèm số lượng sinh viên
===========================================================*/
CREATE OR ALTER VIEW dbo.V_LOP_WithStudentCount
AS
SELECT 
    L.MALOP,
    L.TENLOP,
    L.KHOAHOC,
    L.MAKHOA,
    K.TENKHOA,
    COUNT(SV.MASV) AS SOSINHVIEN
FROM 
    dbo.LOP L WITH (NOLOCK)
    LEFT JOIN dbo.SINHVIEN SV WITH (NOLOCK) ON L.MALOP = SV.MALOP
    LEFT JOIN dbo.KHOA K WITH (NOLOCK) ON L.MAKHOA = K.MAKHOA
GROUP BY 
    L.MALOP, L.TENLOP, L.KHOAHOC, L.MAKHOA, K.TENKHOA;
GO

-- Phân quyền
GRANT SELECT ON dbo.V_LOP_INFO      TO khoa_role, pgv_role;
GRANT SELECT ON dbo.V_SINHVIEN_INFO TO khoa_role, pgv_role, sv_role;
GO 