-- =============================================
-- QLDSV-HTC Roles Creation Script
-- File: 03-security/02-create-roles.sql
-- Purpose: Create custom roles according to project requirements
-- =============================================

USE QLDSV_HTC;
GO

PRINT '🛡️ Creating custom roles for QLDSV-HTC...';

-- =============================================
-- Create Custom Roles theo yêu cầu đề bài
-- =============================================

-- Role PGV (Phòng Giáo Vụ) - Toàn quyền
CREATE ROLE [PGV];
PRINT '✅ Role [PGV] created - Phòng Giáo Vụ (Full Access)';

-- Role KHOA - Quyền hạn chế (không được nhập Khoa, Lớp, GV, SV)
CREATE ROLE [KHOA];
PRINT '✅ Role [KHOA] created - Khoa (Limited Access)';

-- Role SV (Sinh Viên) - Chỉ đăng ký lớp tín chỉ và xem điểm
CREATE ROLE [SV];
PRINT '✅ Role [SV] created - Sinh Viên (Registration & View Only)';

PRINT '🛡️ All custom roles created successfully';
GO 