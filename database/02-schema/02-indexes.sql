USE [$(DB_NAME)];
GO

-- ===============================================
-- INDEXES CHO BẢNG KHOA
-- ===============================================



-- ===============================================
-- INDEXES CHO BẢNG LOP
-- ===============================================

-- Tăng tốc lọc lớp theo khoa và hiển thị tên lớp
IF EXISTS (SELECT 1
           FROM   sys.indexes
           WHERE  object_id = OBJECT_ID(N'dbo.LOP')
             AND  name = N'IX_LOP_MAKHOA')
    DROP INDEX IX_LOP_MAKHOA ON dbo.LOP;
GO

CREATE NONCLUSTERED INDEX IX_LOP_MAKHOA
    ON dbo.LOP (MAKHOA)
    INCLUDE (TENLOP);
GO



-- ===============================================
-- INDEXES CHO BẢNG SINHVIEN
-- ===============================================

-- Phục vụ truy vấn danh sách SV theo lớp + trạng thái nghỉ học
IF EXISTS (SELECT 1
           FROM   sys.indexes
           WHERE  object_id = OBJECT_ID(N'dbo.SINHVIEN')
             AND  name = N'IX_SV_MALOP_DANGHIHOC')
    DROP INDEX IX_SV_MALOP_DANGHIHOC ON dbo.SINHVIEN;
GO

CREATE NONCLUSTERED INDEX IX_SV_MALOP_DANGHIHOC
    ON dbo.SINHVIEN (MALOP, DANGHIHOC)
    INCLUDE (HO, TEN, PHAI, NGAYSINH);
GO



-- ===============================================
-- INDEXES CHO BẢNG MONHOC
-- ===============================================

-- Phục vụ truy vấn TENMH LIKE N'prefix%', tạo index phủ để hạn chế bookmark lookup
IF EXISTS (SELECT 1
           FROM   sys.indexes
           WHERE  object_id = OBJECT_ID(N'dbo.MONHOC')
             AND  name = N'IX_MONHOC_TENMH_PREFIX')
    DROP INDEX IX_MONHOC_TENMH_PREFIX ON dbo.MONHOC;
GO

CREATE NONCLUSTERED INDEX IX_MONHOC_TENMH_PREFIX
    ON dbo.MONHOC (TENMH)
    INCLUDE (MAMH, SOTIET_LT, SOTIET_TH);
GO



-- ===============================================
-- INDEXES CHO BẢNG GIANGVIEN
-- ===============================================



-- ===============================================
-- INDEXES CHO BẢNG LOPTINCHI
-- ===============================================



-- ===============================================
-- INDEXES CHO BẢNG DANGKY
-- ===============================================

