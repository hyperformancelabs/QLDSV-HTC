-- ===============================================
-- QLDSV-HTC Database Data
-- File: 04-insert-monhoc.sql
-- Description: Insert dữ liệu cho bảng MONHOC (60-70 môn học)
-- ===============================================

USE [$(DB_NAME)];
GO

-- Xóa dữ liệu cũ (nếu có)
DELETE FROM [dbo].[MONHOC];
GO

-- INSERT MÔN HỌC ĐẠI CƯƠNG (Foundation subjects)
INSERT INTO [dbo].[MONHOC] ([MAMH], [TENMH], [SOTIET_LT], [SOTIET_TH]) VALUES
('PHI001', N'Triết học Mác-Lênin', 45, 0),
('PHI002', N'Kinh tế chính trị Mác-Lênin', 30, 0),
('PHI003', N'Chủ nghĩa xã hội khoa học', 30, 0),
('PHI004', N'Lịch sử Đảng Cộng sản Việt Nam', 30, 0),
('PHI005', N'Tư tưởng Hồ Chí Minh', 30, 0),
('MAT001', N'Toán cao cấp 1', 60, 15),
('MAT002', N'Toán cao cấp 2', 45, 15),
('MAT003', N'Toán rời rạc', 45, 15),
('MAT004', N'Xác suất thống kê', 45, 15),
('MAT005', N'Toán kinh tế', 45, 0),
('PHY001', N'Vật lý 1 và Thí nghiệm', 45, 30),
('PHY002', N'Vật lý 2 và Thí nghiệm', 45, 30),
('ENG001', N'Tiếng Anh 1', 30, 15),
('ENG002', N'Tiếng Anh 2', 30, 15),
('ENG003', N'Tiếng Anh 3', 30, 15),
('ENG004', N'Tiếng Anh chuyên ngành', 30, 15),
('LAW001', N'Pháp luật đại cương', 30, 0),
('MIL001', N'Giáo dục quốc phòng - An ninh', 45, 30);
GO

-- INSERT MÔN HỌC CNTT (Information Technology subjects)
INSERT INTO [dbo].[MONHOC] ([MAMH], [TENMH], [SOTIET_LT], [SOTIET_TH]) VALUES
('CSE001', N'Tin học cơ sở', 30, 30),
('CSE002', N'Lập trình C', 45, 45),
('CSE003', N'Cấu trúc dữ liệu và giải thuật', 45, 30),
('CSE004', N'Lập trình hướng đối tượng', 45, 45),
('CSE005', N'Cơ sở dữ liệu', 45, 30),
('CSE006', N'Hệ quản trị cơ sở dữ liệu', 30, 30),
('CSE007', N'Mạng máy tính', 45, 30),
('CSE008', N'Hệ điều hành', 45, 30),
('CSE009', N'Kỹ thuật phần mềm', 45, 30),
('CSE010', N'Phát triển ứng dụng Web', 30, 45),
('CSE011', N'Lập trình Java', 30, 45),
('CSE012', N'Lập trình Python', 30, 45),
('CSE013', N'Trí tuệ nhân tạo', 45, 30),
('CSE014', N'Học máy', 45, 30),
('CSE015', N'Xử lý ảnh số', 30, 30),
('CSE016', N'An toàn và bảo mật thông tin', 45, 30);
GO

-- INSERT MÔN HỌC VIỄN THÔNG (Telecommunications subjects)
INSERT INTO [dbo].[MONHOC] ([MAMH], [TENMH], [SOTIET_LT], [SOTIET_TH]) VALUES
('TEL001', N'Kỹ thuật điện tử cơ sở', 45, 30),
('TEL002', N'Tín hiệu và hệ thống', 45, 30),
('TEL003', N'Truyền dẫn và chuyển mạch', 45, 30),
('TEL004', N'Kỹ thuật số và vi xử lý', 45, 30),
('TEL005', N'Mạng viễn thông', 45, 30),
('TEL006', N'Thông tin di động', 45, 30),
('TEL007', N'Hệ thống IoT', 30, 30),
('TEL008', N'Thông tin vô tuyến', 45, 30),
('TEL009', N'An toàn mạng viễn thông', 30, 30),
('TEL010', N'Quản lý dự án viễn thông', 30, 15);
GO

-- INSERT MÔN HỌC QUẢN TRỊ KINH DOANH (Business Administration subjects)
INSERT INTO [dbo].[MONHOC] ([MAMH], [TENMH], [SOTIET_LT], [SOTIET_TH]) VALUES
('BUS001', N'Nguyên lý quản trị học', 45, 15),
('BUS002', N'Kinh tế vi mô', 45, 0),
('BUS003', N'Kinh tế vĩ mô', 45, 0),
('BUS004', N'Nguyên lý kế toán', 45, 15),
('BUS005', N'Marketing căn bản', 45, 15),
('BUS006', N'Tài chính doanh nghiệp', 45, 15),
('BUS007', N'Quản trị nguồn nhân lực', 45, 15),
('BUS008', N'Quản trị chiến lược', 45, 15),
('BUS009', N'Luật doanh nghiệp', 30, 0),
('BUS010', N'Thương mại điện tử', 30, 30),
('BUS011', N'Marketing số', 30, 30),
('BUS012', N'Khởi nghiệp kinh doanh', 30, 15);
GO

-- INSERT MÔN HỌC AN TOÀN THÔNG TIN (Information Security subjects)
INSERT INTO [dbo].[MONHOC] ([MAMH], [TENMH], [SOTIET_LT], [SOTIET_TH]) VALUES
('SEC001', N'Cơ sở an toàn thông tin', 45, 30),
('SEC002', N'Mật mã học', 45, 30),
('SEC003', N'An toàn hệ thống', 45, 30),
('SEC004', N'Phân tích mã độc', 30, 30),
('SEC005', N'Kiểm thử bảo mật', 30, 30),
('SEC006', N'Điều tra số', 30, 30);
GO

-- INSERT MÔN HỌC ĐA PHƯƠNG TIỆN (Multimedia subjects)
INSERT INTO [dbo].[MONHOC] ([MAMH], [TENMH], [SOTIET_LT], [SOTIET_TH]) VALUES
('MED001', N'Thiết kế đồ họa', 30, 45),
('MED002', N'Xử lý âm thanh số', 30, 30),
('MED003', N'Kỹ thuật video số', 30, 30),
('MED004', N'Thiết kế Web', 30, 45),
('MED005', N'Sản xuất phim số', 30, 45),
('MED006', N'Game Development', 30, 45);
GO

-- INSERT MÔN HỌC TỰ CHỌN (Elective subjects)
INSERT INTO [dbo].[MONHOC] ([MAMH], [TENMH], [SOTIET_LT], [SOTIET_TH]) VALUES
('ELE001', N'Đại số tuyến tính', 45, 15),
('ELE002', N'Nghiên cứu khoa học', 30, 15),
('ELE003', N'Kỹ năng giao tiếp', 30, 15),
('ELE004', N'Kỹ năng thuyết trình', 30, 15),
('ELE005', N'Tâm lý học đại cương', 30, 0),
('ELE006', N'Văn hóa doanh nghiệp', 30, 0),
('ELE007', N'Thể dục thể thao', 0, 30);
GO
