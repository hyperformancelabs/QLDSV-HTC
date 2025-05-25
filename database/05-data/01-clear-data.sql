-- =============================================
-- QLDSV-HTC Data Cleanup Script
-- File: 05-data/01-clear-data.sql
-- Purpose: Clear all data from tables for fresh testing
-- =============================================

USE QLDSV_HTC;
GO

PRINT '🗑️ Clearing all data from tables...';

-- Disable foreign key constraints temporarily
EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all";

-- Delete data in reverse dependency order
DELETE FROM DANGKY;
PRINT '🗑️ DANGKY data cleared';

DELETE FROM LOPTINCHI;
PRINT '🗑️ LOPTINCHI data cleared';

DELETE FROM SINHVIEN;
PRINT '🗑️ SINHVIEN data cleared';

DELETE FROM GIANGVIEN;
PRINT '🗑️ GIANGVIEN data cleared';

DELETE FROM LOP;
PRINT '🗑️ LOP data cleared';

DELETE FROM MONHOC;
PRINT '🗑️ MONHOC data cleared';

DELETE FROM KHOA;
PRINT '🗑️ KHOA data cleared';

-- Re-enable foreign key constraints
EXEC sp_MSforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all";

-- Reset identity columns
DBCC CHECKIDENT ('LOPTINCHI', RESEED, 0);
PRINT '🔄 LOPTINCHI identity reset';

PRINT '✅ All data cleared successfully';
GO 