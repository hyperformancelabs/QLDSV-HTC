-- =============================================
-- QLDSV-HTC Basic Seed Data Script
-- File: 05-data/02-seed-basic-data.sql
-- Purpose: Insert basic test data for development
-- =============================================

USE QLDSV_HTC;
GO

PRINT '🌱 Seeding basic data for QLDSV-HTC...';

-- =============================================
-- Insert KHOA (Departments)
-- =============================================

INSERT INTO KHOA (MAKHOA, TENKHOA) VALUES
('CNTT', N'Công nghệ thông tin'),
('KTPM', N'Kỹ thuật phần mềm'),
('HTTT', N'Hệ thống thông tin'),
('KHMT', N'Khoa học máy tính'),
('ATTT', N'An toàn thông tin');

PRINT '✅ KHOA data inserted (5 departments)';

-- =============================================
-- Insert MONHOC (Subjects)
-- =============================================

INSERT INTO MONHOC (MAMH, TENMH, SOTIET_LT, SOTIET_TH) VALUES
('CSDL', N'Cơ sở dữ liệu', 45, 30),
('LTHDT', N'Lập trình hướng đối tượng', 45, 30),
('CTDL', N'Cấu trúc dữ liệu', 45, 30),
('MMT', N'Mạng máy tính', 45, 30),
('PTTKHT', N'Phân tích thiết kế hệ thống', 45, 30),
('CNPM', N'Công nghệ phần mềm', 45, 30),
('ATBMHT', N'An toàn bảo mật hệ thống', 45, 30),
('AI', N'Trí tuệ nhân tạo', 45, 30),
('KTLT', N'Kỹ thuật lập trình', 45, 30),
('TTHCM', N'Toán học cho máy tính', 45, 30);

PRINT '✅ MONHOC data inserted (10 subjects)';

-- =============================================
-- Insert LOP (Classes)
-- =============================================

INSERT INTO LOP (MALOP, TENLOP, KHOAHOC, MAKHOA) VALUES
('CNTT2021', N'Công nghệ thông tin K66', '2021-2025', 'CNTT'),
('CNTT2022', N'Công nghệ thông tin K67', '2022-2026', 'CNTT'),
('KTPM2021', N'Kỹ thuật phần mềm K66', '2021-2025', 'KTPM'),
('KTPM2022', N'Kỹ thuật phần mềm K67', '2022-2026', 'KTPM'),
('HTTT2021', N'Hệ thống thông tin K66', '2021-2025', 'HTTT'),
('HTTT2022', N'Hệ thống thông tin K67', '2022-2026', 'HTTT'),
('KHMT2021', N'Khoa học máy tính K66', '2021-2025', 'KHMT'),
('ATTT2021', N'An toàn thông tin K66', '2021-2025', 'ATTT');

PRINT '✅ LOP data inserted (8 classes)';

-- =============================================
-- Insert GIANGVIEN (Teachers)
-- =============================================

INSERT INTO GIANGVIEN (MAGV, HO, TEN, HOCVI, HOCHAM, CHUYENMON, MAKHOA) VALUES
('GV001', N'Nguyễn Văn', N'An', N'Tiến sĩ', N'Phó giáo sư', N'Cơ sở dữ liệu', 'CNTT'),
('GV002', N'Trần Thị', N'Bình', N'Thạc sĩ', N'Giảng viên', N'Lập trình', 'CNTT'),
('GV003', N'Lê Văn', N'Cường', N'Tiến sĩ', N'Giáo sư', N'Mạng máy tính', 'CNTT'),
('GV004', N'Phạm Thị', N'Dung', N'Thạc sĩ', N'Giảng viên', N'Phần mềm', 'KTPM'),
('GV005', N'Hoàng Văn', N'Em', N'Tiến sĩ', N'Phó giáo sư', N'Hệ thống thông tin', 'HTTT'),
('GV006', N'Vũ Thị', N'Phương', N'Thạc sĩ', N'Giảng viên', N'An toàn thông tin', 'ATTT'),
('GV007', N'Đỗ Văn', N'Giang', N'Tiến sĩ', N'Giảng viên', N'Trí tuệ nhân tạo', 'KHMT'),
('GV008', N'Bùi Thị', N'Hoa', N'Thạc sĩ', N'Giảng viên', N'Toán học', 'KHMT');

PRINT '✅ GIANGVIEN data inserted (8 teachers)';

-- =============================================
-- Insert SINHVIEN (Students)
-- =============================================

INSERT INTO SINHVIEN (MASV, HO, TEN, MALOP, PHAI, NGAYSINH, DIACHI, DANGHIHOC, PASSWORD) VALUES
('SV001', N'Nguyễn Văn', N'Anh', 'CNTT2021', 0, '2003-01-15', N'Hà Nội', 0, '123456'),
('SV002', N'Trần Thị', N'Bảo', 'CNTT2021', 1, '2003-02-20', N'Hồ Chí Minh', 0, '123456'),
('SV003', N'Lê Văn', N'Cường', 'CNTT2021', 0, '2003-03-10', N'Đà Nẵng', 0, '123456'),
('SV004', N'Phạm Thị', N'Duyên', 'KTPM2021', 1, '2003-04-05', N'Hải Phòng', 0, '123456'),
('SV005', N'Hoàng Văn', N'Đức', 'KTPM2021', 0, '2003-05-12', N'Cần Thơ', 0, '123456'),
('SV006', N'Vũ Thị', N'Giang', 'HTTT2021', 1, '2003-06-18', N'Hà Nội', 0, '123456'),
('SV007', N'Đỗ Văn', N'Hùng', 'KHMT2021', 0, '2003-07-22', N'Hồ Chí Minh', 0, '123456'),
('SV008', N'Bùi Thị', N'Lan', 'ATTT2021', 1, '2003-08-30', N'Đà Nẵng', 0, '123456'),
('SV009', N'Cao Văn', N'Minh', 'CNTT2022', 0, '2004-01-10', N'Hà Nội', 0, '123456'),
('SV010', N'Đinh Thị', N'Nga', 'KTPM2022', 1, '2004-02-14', N'Hồ Chí Minh', 0, '123456');

PRINT '✅ SINHVIEN data inserted (10 students)';

-- =============================================
-- Insert LOPTINCHI (Credit Classes)
-- =============================================

INSERT INTO LOPTINCHI (NIENKHOA, HOCKY, MAMH, NHOM, MAGV, MAKHOA, SOSVTOITHIEU, HUYLOP) VALUES
('2023-2024', 1, 'CSDL', 1, 'GV001', 'CNTT', 20, 0),
('2023-2024', 1, 'CSDL', 2, 'GV001', 'CNTT', 20, 0),
('2023-2024', 1, 'LTHDT', 1, 'GV002', 'CNTT', 25, 0),
('2023-2024', 1, 'CTDL', 1, 'GV002', 'CNTT', 25, 0),
('2023-2024', 1, 'MMT', 1, 'GV003', 'CNTT', 20, 0),
('2023-2024', 2, 'PTTKHT', 1, 'GV005', 'HTTT', 20, 0),
('2023-2024', 2, 'CNPM', 1, 'GV004', 'KTPM', 25, 0),
('2023-2024', 2, 'AI', 1, 'GV007', 'KHMT', 15, 0),
('2023-2024', 2, 'ATBMHT', 1, 'GV006', 'ATTT', 20, 0),
('2023-2024', 2, 'TTHCM', 1, 'GV008', 'KHMT', 30, 0);

PRINT '✅ LOPTINCHI data inserted (10 credit classes)';

-- =============================================
-- Insert DANGKY (Registrations)
-- =============================================

-- Semester 1 registrations
INSERT INTO DANGKY (MALTC, MASV, DIEM_CC, DIEM_GK, DIEM_CK, HUYDANGKY) VALUES
(1, 'SV001', 8, 7.5, 8.0, 0),  -- CSDL Nhóm 1
(1, 'SV002', 9, 8.0, 8.5, 0),
(1, 'SV003', 7, 6.5, 7.0, 0),
(2, 'SV004', 8, 7.0, 7.5, 0),  -- CSDL Nhóm 2
(2, 'SV005', 9, 8.5, 9.0, 0),
(3, 'SV001', 8, 8.0, 8.5, 0),  -- LTHDT
(3, 'SV002', 7, 7.5, 8.0, 0),
(3, 'SV006', 9, 8.5, 9.0, 0),
(4, 'SV003', 8, 7.0, 7.5, 0),  -- CTDL
(4, 'SV007', 9, 8.0, 8.5, 0),
(5, 'SV001', 7, 6.5, 7.0, 0),  -- MMT
(5, 'SV008', 8, 7.5, 8.0, 0);

-- Semester 2 registrations (some without grades yet)
INSERT INTO DANGKY (MALTC, MASV, DIEM_CC, DIEM_GK, DIEM_CK, HUYDANGKY) VALUES
(6, 'SV006', NULL, NULL, NULL, 0),  -- PTTKHT
(6, 'SV005', NULL, NULL, NULL, 0),
(7, 'SV004', NULL, NULL, NULL, 0),  -- CNPM
(7, 'SV005', NULL, NULL, NULL, 0),
(8, 'SV007', NULL, NULL, NULL, 0),  -- AI
(9, 'SV008', NULL, NULL, NULL, 0),  -- ATBMHT
(10, 'SV007', NULL, NULL, NULL, 0); -- TTHCM

PRINT '✅ DANGKY data inserted (19 registrations)';

-- =============================================
-- Data Summary
-- =============================================

PRINT '📊 Data seeding summary:';
SELECT 'KHOA' as TableName, COUNT(*) as RecordCount FROM KHOA
UNION ALL
SELECT 'MONHOC', COUNT(*) FROM MONHOC
UNION ALL
SELECT 'LOP', COUNT(*) FROM LOP
UNION ALL
SELECT 'GIANGVIEN', COUNT(*) FROM GIANGVIEN
UNION ALL
SELECT 'SINHVIEN', COUNT(*) FROM SINHVIEN
UNION ALL
SELECT 'LOPTINCHI', COUNT(*) FROM LOPTINCHI
UNION ALL
SELECT 'DANGKY', COUNT(*) FROM DANGKY;

PRINT '🌱 Basic seed data completed successfully!';
GO 