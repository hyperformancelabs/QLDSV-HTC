-- ===============================================
-- QLDSV-HTC Database Data
-- File: 05-insert-giangvien.sql
-- Description: Insert dữ liệu cho bảng GIANGVIEN
-- ===============================================

USE [$(DB_NAME)];
GO

-- Xóa dữ liệu cũ (nếu có)
DELETE FROM [dbo].[GIANGVIEN];
GO

-- INSERT GIẢNG VIÊN MIỀN BẮC - KHOA CNTT1
INSERT INTO [dbo].[GIANGVIEN] ([MAGV], [HO], [TEN], [HOCVI], [HOCHAM], [CHUYENMON], [MAKHOA]) VALUES
('GV001', N'Nguyễn Duy', N'Phương', N'TS', N'Trưởng Khoa', N'Công nghệ thông tin', 'BVH_CNTT1'),
('GV002', N'Nguyễn Mạnh', N'Hùng', N'PGS.TS', N'PGS', N'Công nghệ phần mềm', 'BVH_CNTT1'),
('GV003', N'Trần Đình', N'Quế', N'PGS.TS', N'PGS', N'Công nghệ phần mềm', 'BVH_CNTT1'),
('GV004', N'Đỗ Trung', N'Tuấn', N'PGS.TS', N'PGS', N'Công nghệ phần mềm', 'BVH_CNTT1'),
('GV005', N'Hoàng Hữu', N'Hạnh', N'PGS.TS', N'PGS', N'Công nghệ phần mềm', 'BVH_CNTT1'),
('GV006', N'Đào Ngọc', N'Phong', N'TS', N'Giảng viên', N'Công nghệ phần mềm', 'BVH_CNTT1'),
('GV007', N'Đỗ Thị Bích', N'Ngọc', N'TS', N'Giảng viên', N'Công nghệ phần mềm', 'BVH_CNTT1'),
('GV008', N'Đỗ Thị', N'Liên', N'TS', N'Giảng viên', N'Công nghệ phần mềm', 'BVH_CNTT1'),
('GV009', N'Dương Khánh', N'Chương', N'TS', N'Giảng viên', N'Công nghệ phần mềm', 'BVH_CNTT1'),
('GV010', N'Trần Nhật', N'Quang', N'TS', N'Giảng viên', N'Công nghệ phần mềm', 'BVH_CNTT1'),
('GV011', N'Nguyễn Đình', N'Hiến', N'ThS', N'Giảng viên', N'Công nghệ phần mềm', 'BVH_CNTT1'),
('GV012', N'Trịnh Thị Vân', N'Anh', N'ThS', N'Giảng viên', N'Công nghệ phần mềm', 'BVH_CNTT1'),
('GV013', N'Nguyễn Mạnh', N'Sơn', N'ThS', N'Giảng viên', N'Công nghệ phần mềm', 'BVH_CNTT1'),
('GV014', N'Nguyễn Hoàng', N'Anh', N'ThS', N'Giảng viên', N'Công nghệ phần mềm', 'BVH_CNTT1'),
('GV015', N'Đặng Ngọc', N'Hùng', N'TS', N'Giảng viên', N'Công nghệ phần mềm', 'BVH_CNTT1'),
('GV016', N'Nguyễn Văn', N'Tiến', N'ThS', N'Giảng viên', N'Công nghệ phần mềm', 'BVH_CNTT1'),
('GV017', N'Ngô Tiến', N'Đức', N'ThS', N'Giảng viên', N'Công nghệ phần mềm', 'BVH_CNTT1');
GO

-- INSERT GIẢNG VIÊN MIỀN BẮC - KHOA CNTT1 (Hệ thống thông tin)
INSERT INTO [dbo].[GIANGVIEN] ([MAGV], [HO], [TEN], [HOCVI], [HOCHAM], [CHUYENMON], [MAKHOA]) VALUES
('GV018', N'Nguyễn Trọng', N'Khánh', N'PGS.TS', N'PGS', N'Hệ thống thông tin', 'BVH_CNTT1'),
('GV019', N'Nguyễn Quang', N'Hoan', N'PGS.TS', N'PGS', N'Hệ thống thông tin', 'BVH_CNTT1'),
('GV020', N'Hà Hải', N'Nam', N'PGS.TS', N'PGS', N'Hệ thống thông tin', 'BVH_CNTT1'),
('GV021', N'Dương Trần', N'Đức', N'TS', N'Giảng viên', N'Hệ thống thông tin', 'BVH_CNTT1'),
('GV022', N'Phan Thị', N'Hà', N'TS', N'Giảng viên', N'Cơ sở dữ liệu', 'BVH_CNTT1'),
('GV023', N'Nguyễn Quang', N'Hưng', N'TS', N'Giảng viên', N'Hệ thống thông tin', 'BVH_CNTT1'),
('GV024', N'Nguyễn Đình', N'Hóa', N'TS', N'Giảng viên', N'Hệ thống thông tin', 'BVH_CNTT1'),
('GV025', N'Nguyễn Thanh', N'Thủy', N'TS', N'Giảng viên', N'Hệ thống thông tin', 'BVH_CNTT1'),
('GV026', N'Nguyễn Xuân', N'Anh', N'ThS', N'Giảng viên', N'Hệ thống thông tin', 'BVH_CNTT1'),
('GV027', N'Nguyễn Quỳnh', N'Chi', N'ThS', N'Giảng viên', N'Hệ thống thông tin', 'BVH_CNTT1');
GO

-- INSERT GIẢNG VIÊN MIỀN BẮC - KHOA CNTT1 (Khoa học máy tính)
INSERT INTO [dbo].[GIANGVIEN] ([MAGV], [HO], [TEN], [HOCVI], [HOCHAM], [CHUYENMON], [MAKHOA]) VALUES
('GV028', N'Từ Minh', N'Phương', N'GS.TS', N'GS', N'Khoa học máy tính', 'BVH_CNTT1'),
('GV029', N'Nguyễn Tất', N'Thắng', N'TS', N'Giảng viên', N'Khoa học máy tính', 'BVH_CNTT1'),
('GV030', N'Nguyễn Văn', N'Thoả', N'TS', N'Giảng viên', N'Khoa học máy tính', 'BVH_CNTT1'),
('GV031', N'Đào Thị Thuý', N'Quỳnh', N'TS', N'Giảng viên', N'Khoa học máy tính', 'BVH_CNTT1'),
('GV032', N'Nguyễn Quý', N'Sỹ', N'TS', N'Giảng viên', N'Khoa học máy tính', 'BVH_CNTT1'),
('GV033', N'Đỗ Tiến', N'Dũng', N'TS', N'Giảng viên', N'Khoa học máy tính', 'BVH_CNTT1'),
('GV034', N'Nguyễn Thị Mai', N'Trang', N'TS', N'Giảng viên', N'Khoa học máy tính', 'BVH_CNTT1'),
('GV035', N'Đinh Xuân', N'Trường', N'ThS', N'Giảng viên', N'Khoa học máy tính', 'BVH_CNTT1'),
('GV036', N'Vũ Hoài', N'Thư', N'ThS', N'Giảng viên', N'Khoa học máy tính', 'BVH_CNTT1'),
('GV037', N'Đặng Thị Ngọc', N'Phương', N'KS', N'Trợ lý khoa', N'Công nghệ thông tin', 'BVH_CNTT1');
GO

-- INSERT GIẢNG VIÊN MIỀN BẮC - CÁC KHOA KHÁC
INSERT INTO [dbo].[GIANGVIEN] ([MAGV], [HO], [TEN], [HOCVI], [HOCHAM], [CHUYENMON], [MAKHOA]) VALUES
-- Khoa Viễn thông 1
('GV038', N'Nguyễn Văn', N'Dũng', N'PGS.TS', N'PGS', N'Viễn thông', 'BVH_VT1'),
('GV039', N'Trần Thị', N'Lan', N'TS', N'Giảng viên', N'Mạng viễn thông', 'BVH_VT1'),
('GV040', N'Lê Minh', N'Tuấn', N'TS', N'Giảng viên', N'Thông tin di động', 'BVH_VT1'),
-- Khoa Kỹ thuật Điện tử 1
('GV041', N'Phạm Văn', N'Hòa', N'PGS.TS', N'PGS', N'Kỹ thuật điện tử', 'BVH_KTDT1'),
('GV042', N'Vũ Thị', N'Mai', N'TS', N'Giảng viên', N'Vi xử lý', 'BVH_KTDT1'),
-- Khoa Quản trị kinh doanh 1
('GV043', N'Bùi Thị', N'Hoa', N'PGS.TS', N'PGS', N'Quản trị học', 'BVH_QTKD1'),
('GV044', N'Đặng Văn', N'Nam', N'TS', N'Giảng viên', N'Marketing', 'BVH_QTKD1'),
-- Khoa An toàn thông tin
('GV045', N'Hoàng Văn', N'An', N'PGS.TS', N'PGS', N'An toàn thông tin', 'BVH_ATTT'),
('GV046', N'Lý Thị', N'Bình', N'TS', N'Giảng viên', N'Mật mã học', 'BVH_ATTT'),
-- Khoa Đa phương tiện
('GV047', N'Cao Văn', N'Đức', N'TS', N'Giảng viên', N'Đa phương tiện', 'BVH_DPT'),
('GV048', N'Phan Thị', N'Lan', N'ThS', N'Giảng viên', N'Thiết kế đồ họa', 'BVH_DPT'),
-- Khoa Cơ bản 1
('GV049', N'Nguyễn Văn', N'Hùng', N'PGS.TS', N'PGS', N'Toán học', 'BVH_CB1'),
('GV050', N'Trần Thị', N'Nga', N'TS', N'Giảng viên', N'Vật lý', 'BVH_CB1');
GO

-- INSERT GIẢNG VIÊN MIỀN NAM - KHOA CNTT2
INSERT INTO [dbo].[GIANGVIEN] ([MAGV], [HO], [TEN], [HOCVI], [HOCHAM], [CHUYENMON], [MAKHOA]) VALUES
('GV051', N'Tân', N'Hạnh', N'TS', N'Phó Giám đốc', N'Công nghệ thông tin', 'BVS_CNTT2'),
('GV052', N'Nguyễn Hồng', N'Sơn', N'TS', N'Trưởng Khoa', N'Công nghệ thông tin', 'BVS_CNTT2'),
('GV053', N'Huỳnh Trọng', N'Thưa', N'TS', N'Phó Trưởng khoa', N'An toàn thông tin', 'BVS_CNTT2'),
('GV054', N'Nguyễn Thị Tuyết', N'Hải', N'TS', N'Trưởng BM', N'Khoa học máy tính', 'BVS_CNTT2'),
('GV055', N'Lê Minh', N'Hóa', N'ThS', N'Phụ trách BM', N'Đa phương tiện', 'BVS_CNTT2'),
('GV056', N'Lưu Nguyễn Kỳ', N'Thư', N'ThS', N'Trưởng phòng', N'Quản lý giáo vụ', 'BVS_CNTT2'),
('GV057', N'Nguyễn Minh', N'Tuấn', N'TS', N'Giảng viên', N'Công nghệ phần mềm', 'BVS_CNTT2'),
('GV058', N'Nguyễn Thị Thu', N'Bình', N'ThS', N'Giảng viên', N'Công nghệ thông tin', 'BVS_CNTT2'),
('GV059', N'Nguyễn Ngọc', N'Duy', N'NCS', N'Giảng viên', N'Công nghệ thông tin', 'BVS_CNTT2'),
('GV060', N'Lưu Ngọc', N'Điệp', N'ThS', N'Giảng viên', N'Công nghệ thông tin', 'BVS_CNTT2'),
('GV061', N'Nguyễn Anh', N'Hào', N'ThS', N'Giảng viên', N'Công nghệ thông tin', 'BVS_CNTT2'),
('GV062', N'Nguyễn Trung', N'Hiếu', N'NCS', N'Giảng viên', N'Mạng máy tính', 'BVS_CNTT2'),
('GV063', N'Phan Nghĩa', N'Hiệp', N'ThS', N'Giảng viên', N'Cơ sở dữ liệu', 'BVS_CNTT2'),
('GV064', N'Phan Thanh', N'Hy', N'ThS', N'Giảng viên', N'Lập trình', 'BVS_CNTT2'),
('GV065', N'Nguyễn Công', N'Khanh', N'ThS', N'Giảng viên', N'Hệ thống thông tin', 'BVS_CNTT2');
GO

-- INSERT GIẢNG VIÊN MIỀN NAM - CÁC KHOA KHÁC
INSERT INTO [dbo].[GIANGVIEN] ([MAGV], [HO], [TEN], [HOCVI], [HOCHAM], [CHUYENMON], [MAKHOA]) VALUES
-- Khoa Viễn thông 2
('GV066', N'Đàm Minh', N'Lịnh', N'NCS', N'Giảng viên', N'Viễn thông', 'BVS_VT2'),
('GV067', N'Nguyễn Tất', N'Mão', N'NCS', N'Giảng viên', N'Mạng viễn thông', 'BVS_VT2'),
-- Khoa Quản trị kinh doanh 2
('GV068', N'Nguyễn Thị Bích', N'Nguyên', N'ThS', N'Giảng viên', N'Quản trị kinh doanh', 'BVS_QTKD2'),
('GV069', N'Trương Thị', N'Quyên', N'NCS', N'Giảng viên', N'Marketing', 'BVS_QTKD2'),
('GV070', N'Nguyễn Văn', N'Sáu', N'NCS', N'Giảng viên', N'Tài chính', 'BVS_QTKD2'),
-- Khoa Kỹ thuật Điện tử 2
('GV071', N'Lê Hà', N'Thanh', N'ThS', N'Giảng viên', N'Kỹ thuật điện tử', 'BVS_KTDT2'),
('GV072', N'Nguyễn Hoàng', N'Thành', N'NCS', N'Giảng viên', N'Vi xử lý', 'BVS_KTDT2'),
-- Khoa Cơ bản 2
('GV073', N'Huỳnh Thị Tuyết', N'Trinh', N'NCS', N'Giảng viên', N'Toán học', 'BVS_CB2'),
('GV074', N'Huỳnh Trung', N'Trụ', N'ThS', N'Giảng viên', N'Vật lý', 'BVS_CB2'),
('GV075', N'Châu Văn', N'Vân', N'ThS', N'Giảng viên', N'Tiếng Anh', 'BVS_CB2');
GO

PRINT 'Đã insert thành công ' + CAST(@@ROWCOUNT AS VARCHAR) + ' records vào bảng GIANGVIEN'; 