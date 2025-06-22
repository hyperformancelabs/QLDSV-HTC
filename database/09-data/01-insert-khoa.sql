-- ===============================================
-- QLDSV-HTC Database Data
-- File: 01-insert-khoa.sql
-- Description: Insert dữ liệu cho bảng KHOA
-- ===============================================

USE [$(DB_NAME)];
GO

-- Xóa dữ liệu cũ (nếu có)
DELETE FROM [dbo].[KHOA];
GO

-- Insert dữ liệu khoa miền Bắc (BVH)
INSERT INTO [dbo].[KHOA] ([MAKHOA], [TENKHOA]) VALUES
('BVH_DTSDH', N'Khoa Đào tạo sau đại học'),
('BVH_KHCN',  N'Khoa học công nghệ'),
('BVH_CB1',   N'Khoa cơ bản 1'),
('BVH_CNTT1', N'Khoa Công nghệ thông tin 1'),
('BVH_VT1',   N'Khoa Viễn thông 1'),
('BVH_KTDT1', N'Khoa Kỹ thuật Điện tử 1'),
('BVH_QTKD1', N'Khoa Quản trị kinh doanh 1'),
('BVH_DPT',   N'Khoa Đa phương tiện'),
('BVH_ATTT',  N'Khoa An toàn thông tin');
GO

-- Insert dữ liệu khoa miền Nam (BVS)
INSERT INTO [dbo].[KHOA] ([MAKHOA], [TENKHOA]) VALUES
('BVS_CB2',   N'Khoa Cơ bản 2'),
('BVS_VT2',   N'Khoa Viễn thông 2'),
('BVS_KTDT2', N'Khoa Kỹ thuật Điện tử 2'),
('BVS_QTKD2', N'Khoa Quản trị kinh doanh 2'),
('BVS_CNTT2', N'Khoa Công nghệ thông tin 2');
GO
