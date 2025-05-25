-- =============================================
-- QLDSV-HTC Schema Cleanup Script
-- File: 02-schema/01-drop-tables.sql
-- Purpose: Drop all tables in correct dependency order
-- =============================================

USE QLDSV_HTC;
GO

PRINT '🗑️ Dropping existing schema objects...';

-- Drop tables in reverse dependency order
-- (Child tables first, then parent tables)

-- Drop DANGKY (depends on LOPTINCHI, SINHVIEN)
IF OBJECT_ID('DANGKY', 'U') IS NOT NULL
BEGIN
    DROP TABLE DANGKY;
    PRINT '🗑️ Table DANGKY dropped';
END

-- Drop LOPTINCHI (depends on MONHOC, GIANGVIEN, KHOA)
IF OBJECT_ID('LOPTINCHI', 'U') IS NOT NULL
BEGIN
    DROP TABLE LOPTINCHI;
    PRINT '🗑️ Table LOPTINCHI dropped';
END

-- Drop SINHVIEN (depends on LOP)
IF OBJECT_ID('SINHVIEN', 'U') IS NOT NULL
BEGIN
    DROP TABLE SINHVIEN;
    PRINT '🗑️ Table SINHVIEN dropped';
END

-- Drop GIANGVIEN (depends on KHOA)
IF OBJECT_ID('GIANGVIEN', 'U') IS NOT NULL
BEGIN
    DROP TABLE GIANGVIEN;
    PRINT '🗑️ Table GIANGVIEN dropped';
END

-- Drop LOP (depends on KHOA)
IF OBJECT_ID('LOP', 'U') IS NOT NULL
BEGIN
    DROP TABLE LOP;
    PRINT '🗑️ Table LOP dropped';
END

-- Drop MONHOC (independent)
IF OBJECT_ID('MONHOC', 'U') IS NOT NULL
BEGIN
    DROP TABLE MONHOC;
    PRINT '🗑️ Table MONHOC dropped';
END

-- Drop KHOA (parent table)
IF OBJECT_ID('KHOA', 'U') IS NOT NULL
BEGIN
    DROP TABLE KHOA;
    PRINT '🗑️ Table KHOA dropped';
END

PRINT '✅ All tables dropped successfully';
GO 