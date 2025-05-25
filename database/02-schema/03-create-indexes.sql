-- =============================================
-- QLDSV-HTC Indexes Management Script
-- File: 02-schema/03-create-indexes.sql
-- Purpose: Create performance indexes with DROP/CREATE pattern
-- =============================================

USE QLDSV_HTC;
GO

PRINT '🗑️ Dropping existing indexes...';

-- Drop existing indexes if they exist
DECLARE @sql NVARCHAR(MAX) = '';
SELECT @sql = @sql + 'DROP INDEX ' + i.name + ' ON ' + t.name + ';' + CHAR(13)
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
WHERE i.name LIKE 'IX_%'
  AND t.name IN ('KHOA', 'LOP', 'SINHVIEN', 'MONHOC', 'GIANGVIEN', 'LOPTINCHI', 'DANGKY');

IF LEN(@sql) > 0
BEGIN
    EXEC sp_executesql @sql;
    PRINT '🗑️ Existing indexes dropped';
END

PRINT '📊 Creating performance indexes...';

-- =============================================
-- Foreign Key Indexes
-- =============================================

-- LOP table indexes
CREATE NONCLUSTERED INDEX IX_LOP_MAKHOA ON LOP(MAKHOA);
CREATE NONCLUSTERED INDEX IX_LOP_KHOAHOC ON LOP(KHOAHOC);

-- SINHVIEN table indexes
CREATE NONCLUSTERED INDEX IX_SINHVIEN_MALOP ON SINHVIEN(MALOP);
CREATE NONCLUSTERED INDEX IX_SINHVIEN_DANGHIHOC ON SINHVIEN(DANGHIHOC);
CREATE NONCLUSTERED INDEX IX_SINHVIEN_HO_TEN ON SINHVIEN(HO, TEN);

-- GIANGVIEN table indexes
CREATE NONCLUSTERED INDEX IX_GIANGVIEN_MAKHOA ON GIANGVIEN(MAKHOA);
CREATE NONCLUSTERED INDEX IX_GIANGVIEN_HO_TEN ON GIANGVIEN(HO, TEN);

-- LOPTINCHI table indexes
CREATE NONCLUSTERED INDEX IX_LOPTINCHI_MAMH ON LOPTINCHI(MAMH);
CREATE NONCLUSTERED INDEX IX_LOPTINCHI_MAGV ON LOPTINCHI(MAGV);
CREATE NONCLUSTERED INDEX IX_LOPTINCHI_MAKHOA ON LOPTINCHI(MAKHOA);
CREATE NONCLUSTERED INDEX IX_LOPTINCHI_NIENKHOA_HOCKY ON LOPTINCHI(NIENKHOA, HOCKY);
CREATE NONCLUSTERED INDEX IX_LOPTINCHI_HUYLOP ON LOPTINCHI(HUYLOP);

-- DANGKY table indexes
CREATE NONCLUSTERED INDEX IX_DANGKY_MASV ON DANGKY(MASV);
CREATE NONCLUSTERED INDEX IX_DANGKY_HUYDANGKY ON DANGKY(HUYDANGKY);

-- =============================================
-- Composite Indexes for Common Queries
-- =============================================

-- For course registration queries
CREATE NONCLUSTERED INDEX IX_LOPTINCHI_SEARCH 
ON LOPTINCHI(NIENKHOA, HOCKY, HUYLOP) 
INCLUDE (MAMH, NHOM, MAGV, SOSVTOITHIEU);

-- For grade entry queries
CREATE NONCLUSTERED INDEX IX_DANGKY_GRADE_ENTRY 
ON DANGKY(MALTC, HUYDANGKY) 
INCLUDE (MASV, DIEM_CC, DIEM_GK, DIEM_CK);

-- For student lookup
CREATE NONCLUSTERED INDEX IX_SINHVIEN_LOOKUP 
ON SINHVIEN(DANGHIHOC) 
INCLUDE (MASV, HO, TEN, MALOP);

-- For teacher course assignment
CREATE NONCLUSTERED INDEX IX_LOPTINCHI_TEACHER 
ON LOPTINCHI(MAGV, NIENKHOA, HOCKY) 
INCLUDE (MAMH, NHOM, HUYLOP);

PRINT '✅ All indexes created successfully';

-- =============================================
-- Index Statistics
-- =============================================

PRINT '📊 Index statistics:';
SELECT 
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc AS index_type
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
WHERE t.name IN ('KHOA', 'LOP', 'SINHVIEN', 'MONHOC', 'GIANGVIEN', 'LOPTINCHI', 'DANGKY')
  AND i.name IS NOT NULL
ORDER BY t.name, i.name;

GO 