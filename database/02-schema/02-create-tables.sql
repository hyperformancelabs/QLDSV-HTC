-- =============================================
-- QLDSV-HTC Schema Creation Script
-- File: 02-schema/02-create-tables.sql
-- Purpose: Create all tables in correct dependency order
-- =============================================

USE QLDSV_HTC;
GO

PRINT '🏗️ Creating database schema for QLDSV-HTC...';

-- =============================================
-- Table: KHOA (Parent table - no dependencies)
-- =============================================

CREATE TABLE KHOA (
    MAKHOA nChar(10) NOT NULL,
    TENKHOA nVarchar(50) NOT NULL,
    CONSTRAINT PK_KHOA PRIMARY KEY (MAKHOA),
    CONSTRAINT UK_KHOA_TENKHOA UNIQUE (TENKHOA)
);
PRINT '✅ Table KHOA created';

-- =============================================
-- Table: MONHOC (Independent table)
-- =============================================

CREATE TABLE MONHOC (
    MAMH nChar(10) NOT NULL,
    TENMH nVarchar(50) NOT NULL,
    SOTIET_LT int NOT NULL,
    SOTIET_TH int NOT NULL,
    CONSTRAINT PK_MONHOC PRIMARY KEY (MAMH),
    CONSTRAINT UK_MONHOC_TENMH UNIQUE (TENMH),
    CONSTRAINT CK_MONHOC_SOTIET_LT CHECK (SOTIET_LT >= 0),
    CONSTRAINT CK_MONHOC_SOTIET_TH CHECK (SOTIET_TH >= 0)
);
PRINT '✅ Table MONHOC created';

-- =============================================
-- Table: LOP (Depends on KHOA)
-- =============================================

CREATE TABLE LOP (
    MALOP nChar(10) NOT NULL,
    TENLOP nVarchar(50) NOT NULL,
    KHOAHOC nChar(9) NOT NULL,
    MAKHOA nChar(10) NOT NULL,
    CONSTRAINT PK_LOP PRIMARY KEY (MALOP),
    CONSTRAINT UK_LOP_TENLOP UNIQUE (TENLOP),
    CONSTRAINT FK_LOP_KHOA FOREIGN KEY (MAKHOA) REFERENCES KHOA(MAKHOA)
        ON DELETE CASCADE ON UPDATE CASCADE
);
PRINT '✅ Table LOP created';

-- =============================================
-- Table: GIANGVIEN (Depends on KHOA)
-- =============================================

CREATE TABLE GIANGVIEN (
    MAGV nChar(10) NOT NULL,
    HO nVarchar(50) NOT NULL,
    TEN nVarchar(10) NOT NULL,
    HOCVI nVarchar(20) NULL,
    HOCHAM nVarchar(20) NULL,
    CHUYENMON nVarchar(50) NULL,
    MAKHOA nChar(10) NOT NULL,
    CONSTRAINT PK_GIANGVIEN PRIMARY KEY (MAGV),
    CONSTRAINT FK_GIANGVIEN_KHOA FOREIGN KEY (MAKHOA) REFERENCES KHOA(MAKHOA)
        ON DELETE CASCADE ON UPDATE CASCADE
);
PRINT '✅ Table GIANGVIEN created';

-- =============================================
-- Table: SINHVIEN (Depends on LOP)
-- =============================================

CREATE TABLE SINHVIEN (
    MASV nChar(10) NOT NULL,
    HO nVarchar(50) NOT NULL,
    TEN nVarchar(10) NOT NULL,
    MALOP nChar(10) NOT NULL,
    PHAI bit DEFAULT 0, -- false: Nam; true: Nữ
    NGAYSINH datetime NULL,
    DIACHI nVarchar(100) NULL,
    DANGHIHOC bit DEFAULT 0,
    PASSWORD nVarchar(40) DEFAULT '123456',
    CONSTRAINT PK_SINHVIEN PRIMARY KEY (MASV),
    CONSTRAINT FK_SINHVIEN_LOP FOREIGN KEY (MALOP) REFERENCES LOP(MALOP)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT CK_SINHVIEN_NGAYSINH CHECK (NGAYSINH <= GETDATE())
);
PRINT '✅ Table SINHVIEN created';

-- =============================================
-- Table: LOPTINCHI (Depends on MONHOC, GIANGVIEN, KHOA)
-- =============================================

CREATE TABLE LOPTINCHI (
    MALTC int IDENTITY(1,1) NOT NULL,
    NIENKHOA nChar(9) NOT NULL,
    HOCKY int NOT NULL,
    MAMH nChar(10) NOT NULL,
    NHOM int NOT NULL,
    MAGV nChar(10) NOT NULL,
    MAKHOA nChar(10) NOT NULL,
    SOSVTOITHIEU smallint NOT NULL,
    HUYLOP bit DEFAULT 0,
    CONSTRAINT PK_LOPTINCHI PRIMARY KEY (MALTC),
    CONSTRAINT UK_LOPTINCHI_UNIQUE UNIQUE (NIENKHOA, HOCKY, MAMH, NHOM),
    CONSTRAINT FK_LOPTINCHI_MONHOC FOREIGN KEY (MAMH) REFERENCES MONHOC(MAMH)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_LOPTINCHI_GIANGVIEN FOREIGN KEY (MAGV) REFERENCES GIANGVIEN(MAGV)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_LOPTINCHI_KHOA FOREIGN KEY (MAKHOA) REFERENCES KHOA(MAKHOA)
        ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT CK_LOPTINCHI_HOCKY CHECK (HOCKY >= 1 AND HOCKY <= 3),
    CONSTRAINT CK_LOPTINCHI_NHOM CHECK (NHOM >= 1),
    CONSTRAINT CK_LOPTINCHI_SOSVTOITHIEU CHECK (SOSVTOITHIEU > 0)
);
PRINT '✅ Table LOPTINCHI created';

-- =============================================
-- Table: DANGKY (Depends on LOPTINCHI, SINHVIEN)
-- =============================================

CREATE TABLE DANGKY (
    MALTC int NOT NULL,
    MASV nChar(10) NOT NULL,
    DIEM_CC int NULL,
    DIEM_GK float NULL,
    DIEM_CK float NULL,
    HUYDANGKY bit DEFAULT 0,
    CONSTRAINT PK_DANGKY PRIMARY KEY (MALTC, MASV),
    CONSTRAINT FK_DANGKY_LOPTINCHI FOREIGN KEY (MALTC) REFERENCES LOPTINCHI(MALTC)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_DANGKY_SINHVIEN FOREIGN KEY (MASV) REFERENCES SINHVIEN(MASV)
        ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT CK_DANGKY_DIEM_CC CHECK (DIEM_CC >= 0 AND DIEM_CC <= 10),
    CONSTRAINT CK_DANGKY_DIEM_GK CHECK (DIEM_GK >= 0 AND DIEM_GK <= 10),
    CONSTRAINT CK_DANGKY_DIEM_CK CHECK (DIEM_CK >= 0 AND DIEM_CK <= 10)
);
PRINT '✅ Table DANGKY created';

PRINT '🏗️ Database schema creation completed successfully!';
GO 