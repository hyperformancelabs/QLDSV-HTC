-- =============================================
-- QLDSV-HTC Permissions Configuration Script
-- File: 03-security/04-set-permissions.sql
-- Purpose: Set detailed permissions according to project requirements
-- =============================================

USE QLDSV_HTC;
GO

PRINT '🛡️ Configuring detailed permissions according to project requirements...';

-- =============================================
-- KHOA Role Restrictions (theo đề bài)
-- Không được nhập Khoa, Lớp, Giảng viên, Sinh viên
-- =============================================

PRINT '🚫 Setting KHOA role restrictions...';

-- Deny INSERT, UPDATE, DELETE on restricted tables
DENY INSERT, UPDATE, DELETE ON KHOA TO KHOA;
DENY INSERT, UPDATE, DELETE ON LOP TO KHOA;
DENY INSERT, UPDATE, DELETE ON GIANGVIEN TO KHOA;
DENY INSERT, UPDATE, DELETE ON SINHVIEN TO KHOA;

-- Allow full access to other tables
GRANT SELECT, INSERT, UPDATE, DELETE ON MONHOC TO KHOA;
GRANT SELECT, INSERT, UPDATE, DELETE ON LOPTINCHI TO KHOA;
GRANT SELECT, INSERT, UPDATE ON DANGKY TO KHOA; -- No DELETE for grades

PRINT '✅ KHOA role restrictions applied';

-- =============================================
-- SV Role Permissions (theo đề bài)
-- Chỉ đăng ký lớp tín chỉ, xem phiếu điểm của chính mình
-- =============================================

PRINT '👨‍🎓 Setting SV role permissions...';

-- Read access to necessary tables for course registration
GRANT SELECT ON KHOA TO SV;
GRANT SELECT ON LOP TO SV;
GRANT SELECT ON MONHOC TO SV;
GRANT SELECT ON GIANGVIEN TO SV;
GRANT SELECT ON LOPTINCHI TO SV;

-- Course registration permissions
GRANT INSERT ON DANGKY TO SV;
GRANT SELECT ON DANGKY TO SV;

-- Limited access to student info (for their own records)
GRANT SELECT ON SINHVIEN TO SV;

-- Deny modifications to core data
DENY INSERT, UPDATE, DELETE ON KHOA TO SV;
DENY INSERT, UPDATE, DELETE ON LOP TO SV;
DENY INSERT, UPDATE, DELETE ON MONHOC TO SV;
DENY INSERT, UPDATE, DELETE ON GIANGVIEN TO SV;
DENY INSERT, UPDATE, DELETE ON SINHVIEN TO SV;
DENY INSERT, UPDATE, DELETE ON LOPTINCHI TO SV;
DENY UPDATE, DELETE ON DANGKY TO SV; -- Can only register, not modify grades

PRINT '✅ SV role permissions applied';

-- =============================================
-- Application Backend Permissions
-- =============================================

PRINT '🔧 Setting application backend permissions...';

-- Grant backup permissions for backup/restore functionality
ALTER ROLE [db_backupoperator] ADD MEMBER [qldsv_app];

-- Grant execute permissions on system procedures
GRANT EXECUTE ON SCHEMA::dbo TO [qldsv_app];

PRINT '✅ Application backend permissions applied';

-- =============================================
-- Verify Permissions
-- =============================================

PRINT '🔍 Verifying permissions configuration...';

-- Show role memberships
SELECT 
    dp.name AS principal_name,
    dp.type_desc AS principal_type,
    r.name AS role_name,
    CASE 
        WHEN r.name = 'db_owner' THEN 'Full Access'
        WHEN r.name = 'PGV' THEN 'Phòng Giáo Vụ - Full Access'
        WHEN r.name = 'KHOA' THEN 'Khoa - Limited Access'
        WHEN r.name = 'SV' THEN 'Sinh Viên - Registration Only'
        ELSE r.name
    END AS role_description
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members rm ON dp.principal_id = rm.member_principal_id
LEFT JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
WHERE dp.name IN ('qldsv_app', 'pgv_user', 'khoa_user', 'sv')
ORDER BY dp.name, r.name;

-- Show explicit permissions
SELECT 
    p.state_desc AS permission_state,
    p.permission_name,
    s.name AS securable_name,
    pr.name AS principal_name
FROM sys.database_permissions p
LEFT JOIN sys.objects s ON p.major_id = s.object_id
LEFT JOIN sys.database_principals pr ON p.grantee_principal_id = pr.principal_id
WHERE pr.name IN ('KHOA', 'SV', 'qldsv_app')
ORDER BY pr.name, s.name, p.permission_name;

PRINT '🛡️ Permissions configuration completed successfully!';
GO 