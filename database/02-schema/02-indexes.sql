USE [$(DB_NAME)];
GO

-- ===============================================
-- INDEXES CHO BẢNG KHOA
-- ===============================================



-- ===============================================
-- INDEXES CHO BẢNG LOP
-- ===============================================



-- ===============================================
-- INDEXES CHO BẢNG SINHVIEN
-- ===============================================



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

