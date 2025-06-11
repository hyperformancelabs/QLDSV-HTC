-- ===============================================
-- QLDSV-HTC Database Schema
-- File: 01-tables.sql
-- Description: Tạo tất cả các bảng chính cho hệ thống QLDSV-HTC
-- ===============================================

USE [$(DB_NAME)];
GO

-- ===============================================
-- 1. BẢNG KHOA
-- ===============================================
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[KHOA]'))
DROP TABLE [dbo].[KHOA]
GO

CREATE TABLE [dbo].[KHOA](
    [MAKHOA] NCHAR(10) NOT NULL,
    [TENKHOA] NVARCHAR(50) NOT NULL,
    CONSTRAINT [PK_KHOA] PRIMARY KEY CLUSTERED ([MAKHOA] ASC),
    CONSTRAINT [UK_KHOA_TENKHOA] UNIQUE ([TENKHOA])
) ON [PRIMARY]
GO

-- ===============================================
-- 2. BẢNG LOP
-- ===============================================
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[LOP]'))
DROP TABLE [dbo].[LOP]
GO

CREATE TABLE [dbo].[LOP](
    [MALOP] NCHAR(10) NOT NULL,
    [TENLOP] NVARCHAR(50) NOT NULL,
    [KHOAHOC] NCHAR(9) NOT NULL,
    [MAKHOA] NCHAR(10) NOT NULL,
    CONSTRAINT [PK_LOP] PRIMARY KEY CLUSTERED ([MALOP] ASC),
    CONSTRAINT [UK_LOP_TENLOP] UNIQUE ([TENLOP]),
    CONSTRAINT [FK_LOP_KHOA] FOREIGN KEY ([MAKHOA]) 
        REFERENCES [dbo].[KHOA] ([MAKHOA])
) ON [PRIMARY]
GO

-- ===============================================
-- 3. BẢNG SINHVIEN
-- ===============================================
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SINHVIEN]'))
DROP TABLE [dbo].[SINHVIEN]
GO

CREATE TABLE [dbo].[SINHVIEN](
    [MASV] NCHAR(10) NOT NULL,
    [HO] NVARCHAR(50) NOT NULL,
    [TEN] NVARCHAR(10) NOT NULL,
    [MALOP] NCHAR(10) NOT NULL,
    [PHAI] BIT NOT NULL DEFAULT 0, -- 0: Nam, 1: Nữ
    [NGAYSINH] DATETIME NULL,
    [DIACHI] NVARCHAR(100) NULL,
    [DANGHIHOC] BIT NOT NULL DEFAULT 0, -- 0: Đang học, 1: Nghỉ học
    [PASSWORD] NVARCHAR(40) NULL DEFAULT N'123456',
    CONSTRAINT [PK_SINHVIEN] PRIMARY KEY CLUSTERED ([MASV] ASC),
    CONSTRAINT [FK_SINHVIEN_LOP] FOREIGN KEY ([MALOP]) 
        REFERENCES [dbo].[LOP] ([MALOP])
) ON [PRIMARY]
GO

-- ===============================================
-- 4. BẢNG MONHOC
-- ===============================================
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MONHOC]'))
DROP TABLE [dbo].[MONHOC]
GO

CREATE TABLE [dbo].[MONHOC](
    [MAMH] NCHAR(10) NOT NULL,
    [TENMH] NVARCHAR(50) NOT NULL,
    [SOTIET_LT] INT NOT NULL, -- Số tiết lý thuyết
    [SOTIET_TH] INT NOT NULL, -- Số tiết thực hành
    CONSTRAINT [PK_MONHOC] PRIMARY KEY CLUSTERED ([MAMH] ASC),
    CONSTRAINT [UK_MONHOC_TENMH] UNIQUE ([TENMH])
) ON [PRIMARY]
GO

-- ===============================================
-- 5. BẢNG GIANGVIEN
-- ===============================================
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GIANGVIEN]'))
DROP TABLE [dbo].[GIANGVIEN]
GO

CREATE TABLE [dbo].[GIANGVIEN](
    [MAGV] NCHAR(10) NOT NULL,
    [HO] NVARCHAR(50) NOT NULL,
    [TEN] NVARCHAR(10) NOT NULL,
    [HOCVI] NVARCHAR(20) NULL,
    [HOCHAM] NVARCHAR(20) NULL,
    [CHUYENMON] NVARCHAR(50) NULL,
    [MAKHOA] NCHAR(10) NOT NULL,
    CONSTRAINT [PK_GIANGVIEN] PRIMARY KEY CLUSTERED ([MAGV] ASC),
    CONSTRAINT [FK_GIANGVIEN_KHOA] FOREIGN KEY ([MAKHOA]) 
        REFERENCES [dbo].[KHOA] ([MAKHOA])
) ON [PRIMARY]
GO

-- ===============================================
-- 6. BẢNG LOPTINCHI
-- ===============================================
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[LOPTINCHI]'))
DROP TABLE [dbo].[LOPTINCHI]
GO

CREATE TABLE [dbo].[LOPTINCHI](
    [MALTC] INT IDENTITY(1,1) NOT NULL,
    [NIENKHOA] NCHAR(9) NOT NULL,
    [HOCKY] INT NOT NULL,
    [MAMH] NCHAR(10) NOT NULL,
    [NHOM] INT NOT NULL,
    [MAGV] NCHAR(10) NOT NULL,
    [MAKHOA] NCHAR(10) NOT NULL, -- Khoa quản lý lớp tín chỉ
    [SOSVTOITHIEU] SMALLINT NOT NULL,
    [HUYLOP] BIT NOT NULL DEFAULT 0, -- 0: Chưa hủy, 1: Đã hủy
    CONSTRAINT [PK_LOPTINCHI] PRIMARY KEY CLUSTERED ([MALTC] ASC),
    CONSTRAINT [UK_LOPTINCHI_UNIQUE] UNIQUE ([NIENKHOA], [HOCKY], [MAMH], [NHOM]),
    CONSTRAINT [FK_LOPTINCHI_MONHOC] FOREIGN KEY ([MAMH]) 
        REFERENCES [dbo].[MONHOC] ([MAMH]),
    CONSTRAINT [FK_LOPTINCHI_GIANGVIEN] FOREIGN KEY ([MAGV]) 
        REFERENCES [dbo].[GIANGVIEN] ([MAGV]),
    CONSTRAINT [FK_LOPTINCHI_KHOA] FOREIGN KEY ([MAKHOA]) 
        REFERENCES [dbo].[KHOA] ([MAKHOA]),
    CONSTRAINT [CK_LOPTINCHI_HOCKY] CHECK ([HOCKY] >= 1 AND [HOCKY] <= 3),
    CONSTRAINT [CK_LOPTINCHI_NHOM] CHECK ([NHOM] >= 1),
    CONSTRAINT [CK_LOPTINCHI_SOSVTOITHIEU] CHECK ([SOSVTOITHIEU] > 0)
) ON [PRIMARY]
GO

-- ===============================================
-- 7. BẢNG DANGKY
-- ===============================================
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DANGKY]'))
DROP TABLE [dbo].[DANGKY]
GO

CREATE TABLE [dbo].[DANGKY](
    [MALTC] INT NOT NULL,
    [MASV] NCHAR(10) NOT NULL,
    [DIEM_CC] INT NULL, -- Điểm chuyên cần (0-10)
    [DIEM_GK] FLOAT NULL, -- Điểm giữa kỳ (0-10, làm tròn 0.5)
    [DIEM_CK] FLOAT NULL, -- Điểm cuối kỳ (0-10, làm tròn 0.5)
    [HUYDANGKY] BIT NOT NULL DEFAULT 0, -- 0: Chưa hủy, 1: Đã hủy
    CONSTRAINT [PK_DANGKY] PRIMARY KEY CLUSTERED ([MALTC], [MASV]),
    CONSTRAINT [FK_DANGKY_LOPTINCHI] FOREIGN KEY ([MALTC]) 
        REFERENCES [dbo].[LOPTINCHI] ([MALTC]),
    CONSTRAINT [FK_DANGKY_SINHVIEN] FOREIGN KEY ([MASV]) 
        REFERENCES [dbo].[SINHVIEN] ([MASV]),
    CONSTRAINT [CK_DANGKY_DIEM_CC] CHECK ([DIEM_CC] IS NULL OR ([DIEM_CC] >= 0 AND [DIEM_CC] <= 10)),
    CONSTRAINT [CK_DANGKY_DIEM_GK] CHECK ([DIEM_GK] IS NULL OR ([DIEM_GK] >= 0 AND [DIEM_GK] <= 10)),
    CONSTRAINT [CK_DANGKY_DIEM_CK] CHECK ([DIEM_CK] IS NULL OR ([DIEM_CK] >= 0 AND [DIEM_CK] <= 10))
) ON [PRIMARY]
GO

PRINT 'Schema tables created successfully'; 