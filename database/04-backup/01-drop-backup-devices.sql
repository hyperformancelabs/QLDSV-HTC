-- =============================================
-- QLDSV-HTC Backup Devices Cleanup Script
-- File: 04-backup/01-drop-backup-devices.sql
-- Purpose: Drop existing backup devices for clean setup
-- =============================================

USE master;
GO

PRINT '🗑️ Cleaning up existing backup devices...';

-- Drop backup devices if they exist
DECLARE @devices TABLE (device_name NVARCHAR(128));
INSERT INTO @devices VALUES 
    ('DEVICE_QLDSV_HTC'),
    ('DEVICE_QLDSV_HTC_LOG'),
    ('DEVICE_QLDSV_HTC_DIFF');

DECLARE @device_name NVARCHAR(128);
DECLARE device_cursor CURSOR FOR SELECT device_name FROM @devices;

OPEN device_cursor;
FETCH NEXT FROM device_cursor INTO @device_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF EXISTS (SELECT name FROM sys.backup_devices WHERE name = @device_name)
    BEGIN
        EXEC sp_dropdevice @device_name, 'delfile';
        PRINT '🗑️ Backup device ' + @device_name + ' dropped';
    END
    FETCH NEXT FROM device_cursor INTO @device_name;
END

CLOSE device_cursor;
DEALLOCATE device_cursor;

PRINT '✅ Backup devices cleanup completed';
GO 