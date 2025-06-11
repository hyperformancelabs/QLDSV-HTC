-- ===============================================
-- QLDSV-HTC Database Indexes
-- File: 02-indexes.sql
-- Description: Tạo các indexes để tối ưu hiệu năng truy vấn
-- ===============================================

USE [$(DB_NAME)];
GO

-- ===============================================
-- INDEXES CHO BẢNG SINHVIEN
-- ===============================================

-- Index để tìm kiếm sinh viên theo lớp (dùng nhiều trong báo cáo)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_SINHVIEN_MALOP' AND object_id = OBJECT_ID('dbo.SINHVIEN'))
CREATE NONCLUSTERED INDEX [IX_SINHVIEN_MALOP] 
ON [dbo].[SINHVIEN] ([MALOP])
INCLUDE ([HO], [TEN], [PHAI], [DANGHIHOC])
GO

-- Index để tìm kiếm sinh viên đang học
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_SINHVIEN_DANGHIHOC' AND object_id = OBJECT_ID('dbo.SINHVIEN'))
CREATE NONCLUSTERED INDEX [IX_SINHVIEN_DANGHIHOC] 
ON [dbo].[SINHVIEN] ([DANGHIHOC])
INCLUDE ([HO], [TEN], [MALOP])
GO

-- Index để sắp xếp theo tên (dùng trong báo cáo)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_SINHVIEN_HOTEN' AND object_id = OBJECT_ID('dbo.SINHVIEN'))
CREATE NONCLUSTERED INDEX [IX_SINHVIEN_HOTEN] 
ON [dbo].[SINHVIEN] ([TEN], [HO])
GO

-- ===============================================
-- INDEXES CHO BẢNG LOPTINCHI
-- ===============================================

-- Index cho truy vấn lớp tín chỉ theo niên khóa, học kỳ
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_LOPTINCHI_NIENKHOA_HOCKY' AND object_id = OBJECT_ID('dbo.LOPTINCHI'))
CREATE NONCLUSTERED INDEX [IX_LOPTINCHI_NIENKHOA_HOCKY] 
ON [dbo].[LOPTINCHI] ([NIENKHOA], [HOCKY], [HUYLOP])
INCLUDE ([MAMH], [NHOM], [MAGV], [MAKHOA], [SOSVTOITHIEU])
GO

-- Index cho truy vấn lớp tín chỉ theo khoa
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_LOPTINCHI_MAKHOA' AND object_id = OBJECT_ID('dbo.LOPTINCHI'))
CREATE NONCLUSTERED INDEX [IX_LOPTINCHI_MAKHOA] 
ON [dbo].[LOPTINCHI] ([MAKHOA], [HUYLOP])
INCLUDE ([NIENKHOA], [HOCKY], [MAMH], [NHOM])
GO

-- Index cho truy vấn lớp tín chỉ theo môn học
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_LOPTINCHI_MAMH' AND object_id = OBJECT_ID('dbo.LOPTINCHI'))
CREATE NONCLUSTERED INDEX [IX_LOPTINCHI_MAMH] 
ON [dbo].[LOPTINCHI] ([MAMH], [NIENKHOA], [HOCKY])
INCLUDE ([NHOM], [MAGV], [HUYLOP])
GO

-- Index cho truy vấn lớp tín chỉ theo giảng viên
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_LOPTINCHI_MAGV' AND object_id = OBJECT_ID('dbo.LOPTINCHI'))
CREATE NONCLUSTERED INDEX [IX_LOPTINCHI_MAGV] 
ON [dbo].[LOPTINCHI] ([MAGV])
INCLUDE ([NIENKHOA], [HOCKY], [MAMH], [NHOM], [HUYLOP])
GO

-- ===============================================
-- INDEXES CHO BẢNG DANGKY
-- ===============================================

-- Index cho truy vấn đăng ký theo lớp tín chỉ
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DANGKY_MALTC' AND object_id = OBJECT_ID('dbo.DANGKY'))
CREATE NONCLUSTERED INDEX [IX_DANGKY_MALTC] 
ON [dbo].[DANGKY] ([MALTC], [HUYDANGKY])
INCLUDE ([MASV], [DIEM_CC], [DIEM_GK], [DIEM_CK])
GO

-- Index cho truy vấn đăng ký theo sinh viên
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DANGKY_MASV' AND object_id = OBJECT_ID('dbo.DANGKY'))
CREATE NONCLUSTERED INDEX [IX_DANGKY_MASV] 
ON [dbo].[DANGKY] ([MASV], [HUYDANGKY])
INCLUDE ([MALTC], [DIEM_CC], [DIEM_GK], [DIEM_CK])
GO

-- ===============================================
-- INDEXES CHO BẢNG GIANGVIEN
-- ===============================================

-- Index cho truy vấn giảng viên theo khoa
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_GIANGVIEN_MAKHOA' AND object_id = OBJECT_ID('dbo.GIANGVIEN'))
CREATE NONCLUSTERED INDEX [IX_GIANGVIEN_MAKHOA] 
ON [dbo].[GIANGVIEN] ([MAKHOA])
INCLUDE ([HO], [TEN], [HOCVI], [HOCHAM], [CHUYENMON])
GO

-- Index để sắp xếp giảng viên theo tên
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_GIANGVIEN_HOTEN' AND object_id = OBJECT_ID('dbo.GIANGVIEN'))
CREATE NONCLUSTERED INDEX [IX_GIANGVIEN_HOTEN] 
ON [dbo].[GIANGVIEN] ([TEN], [HO])
GO

-- ===============================================
-- INDEXES CHO BẢNG LOP
-- ===============================================

-- Index cho truy vấn lớp theo khoa
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_LOP_MAKHOA' AND object_id = OBJECT_ID('dbo.LOP'))
CREATE NONCLUSTERED INDEX [IX_LOP_MAKHOA] 
ON [dbo].[LOP] ([MAKHOA])
INCLUDE ([TENLOP], [KHOAHOC])
GO

-- Index cho truy vấn lớp theo khóa học
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_LOP_KHOAHOC' AND object_id = OBJECT_ID('dbo.LOP'))
CREATE NONCLUSTERED INDEX [IX_LOP_KHOAHOC] 
ON [dbo].[LOP] ([KHOAHOC])
INCLUDE ([TENLOP], [MAKHOA])
GO

-- ===============================================
-- INDEXES CHO BẢNG HOCPHI
-- ===============================================

-- ===============================================
-- INDEXES CHO BẢNG CT_DONGHOCPHI
-- ===============================================

PRINT 'Database indexes created successfully'; 