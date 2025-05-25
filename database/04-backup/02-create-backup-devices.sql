-- =============================================
-- QLDSV-HTC Backup Devices Setup Script
-- File: 04-backup/02-create-backup-devices.sql
-- Purpose: Create backup devices according to project requirements
-- =============================================

USE master;
GO

PRINT '💾 Setting up backup devices for QLDSV-HTC...';

-- =============================================
-- Create Backup Devices theo yêu cầu đề bài
-- =============================================

-- Full Backup Device
EXEC sp_addumpdevice 
    @devtype = 'disk',
    @logicalname = 'DEVICE_QLDSV_HTC', 
    @physicalname = '/var/backups/QLDSV_HTC.bak';
PRINT '✅ Full backup device DEVICE_QLDSV_HTC created';

-- Transaction Log Backup Device
EXEC sp_addumpdevice 
    @devtype = 'disk',
    @logicalname = 'DEVICE_QLDSV_HTC_LOG', 
    @physicalname = '/var/backups/QLDSV_HTC_LOG.trn';
PRINT '✅ Log backup device DEVICE_QLDSV_HTC_LOG created';

-- Differential Backup Device
EXEC sp_addumpdevice 
    @devtype = 'disk',
    @logicalname = 'DEVICE_QLDSV_HTC_DIFF', 
    @physicalname = '/var/backups/QLDSV_HTC_DIFF.bak';
PRINT '✅ Differential backup device DEVICE_QLDSV_HTC_DIFF created';

-- =============================================
-- Configure Database for Backup
-- =============================================

-- Set Recovery Model to FULL for point-in-time recovery
ALTER DATABASE QLDSV_HTC SET RECOVERY FULL;
PRINT '✅ Database recovery model set to FULL';

-- =============================================
-- Initial Full Backup
-- =============================================

PRINT '📦 Creating initial full backup...';

BACKUP DATABASE QLDSV_HTC TO DEVICE_QLDSV_HTC
WITH 
    FORMAT,
    INIT,
    NAME = 'QLDSV_HTC Initial Full Backup',
    DESCRIPTION = 'Initial backup after database setup',
    COMPRESSION,
    STATS = 10;

PRINT '✅ Initial backup completed successfully';

-- =============================================
-- Verify Backup Devices
-- =============================================

PRINT '🔍 Verifying backup devices...';

SELECT 
    name AS device_name,
    physical_name,
    type_desc
FROM sys.backup_devices
WHERE name LIKE 'DEVICE_QLDSV_HTC%'
ORDER BY name;

PRINT '💾 Backup devices setup completed successfully!';
GO 