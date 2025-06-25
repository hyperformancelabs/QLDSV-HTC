/*
===========================================================
  File        : 06-loptinchi-dangky-procedures.sql
  Description : Stored procedures cho LOPTINCHI & DANGKY
===========================================================
*/

USE [$(DB_NAME)];
GO

/*
===========================================================
  Helper: Determine if a NIENKHOA + HOCKY is in the past
  Rules  :
    - NIENKHOA có định dạng 'YYYY-YYYY'. Lấy 4 ký tự đầu => StartYear
    - Học kỳ hiện tại xác định theo tháng hệ quy chiếu:
        * Tháng 1-4  => Học kỳ 2 (HK=2)
        * Tháng 5-8  => Học kỳ 3 (HK=3)
        * Tháng 9-12 => Học kỳ 1 (HK=1)
    - Quá khứ khi:
        * StartYear < Năm hiện tại OR
        * StartYear = Năm hiện tại AND HOCKY < Học kỳ hiện tại
===========================================================
*/
CREATE OR ALTER FUNCTION dbo.FN_IsSemesterPast (
    @NIENKHOA NCHAR(9),
    @HOCKY    INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @StartYear INT = TRY_CAST(LEFT(@NIENKHOA,4) AS INT);
    IF @StartYear IS NULL RETURN 1; -- lỗi format → xem như quá khứ để tránh can thiệp

    DECLARE @CurYear INT   = YEAR(GETDATE());
    DECLARE @CurMonth INT  = MONTH(GETDATE());

    /*
       Xác định NIÊN KHÓA hiện tại: 
         - Nếu tháng >= 8 (bắt đầu HK1) ⇒ AcademicStartYear = CurYear
         - Ngược lại (tháng 1-7)      ⇒ AcademicStartYear = CurYear - 1
    */
    DECLARE @CurAcademicStartYear INT = CASE WHEN @CurMonth >= 8 THEN @CurYear ELSE @CurYear - 1 END;

    /* Học kỳ hiện tại theo tháng */
    DECLARE @CurSemester INT = CASE
                                 WHEN @CurMonth BETWEEN 8 AND 12 OR @CurMonth = 1 THEN 1
                                 WHEN @CurMonth BETWEEN 2 AND 5                THEN 2
                                 ELSE 3  -- 6-7
                               END;

    DECLARE @IsPast BIT = CASE 
                             WHEN @StartYear < @CurAcademicStartYear THEN 1
                             WHEN @StartYear = @CurAcademicStartYear AND @HOCKY < @CurSemester THEN 1
                             ELSE 0
                           END;

    RETURN @IsPast;
END;
GO

/*
===========================================================
  SP_LTC_Upsert  – Thêm/Sửa Lớp tín chỉ
  Parameters:
      @ACTION    NVARCHAR(6) = 'INSERT' | 'UPDATE'
      @MALTC     INT OUTPUT (để trả về mã lớp tín chỉ mới khi INSERT)
      @NIENKHOA  NCHAR(9)
      @HOCKY     INT (1..3)
      @MAMH      NCHAR(10)
      @NHOM      INT (>=1)
      @MAGV      NCHAR(10)
      @MAKHOA    NCHAR(10)
      @SOSVTOITHIEU SMALLINT
===========================================================
  Validation:
    - Không can thiệp lớp quá khứ (FN_IsSemesterPast)
    - Unique (NIENKHOA, HOCKY, MAMH, NHOM)
===========================================================
*/
CREATE OR ALTER PROCEDURE dbo.SP_LTC_Upsert
    @ACTION          NVARCHAR(6),
    @MALTC           INT          OUTPUT,
    @NIENKHOA        NCHAR(9),
    @HOCKY           INT,
    @MAMH            NCHAR(10),
    @NHOM            INT,
    @MAGV            NCHAR(10),
    @MAKHOA          NCHAR(10),
    @SOSVTOITHIEU    SMALLINT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra thời gian
    IF dbo.FN_IsSemesterPast(@NIENKHOA, @HOCKY) = 1
    BEGIN
        RAISERROR(N'Không được phép chỉnh sửa lớp tín chỉ trong quá khứ', 16, 1);
        RETURN;
    END;

    -- Kiểm tra hợp lệ học kỳ
    IF @HOCKY NOT BETWEEN 1 AND 3
    BEGIN
        RAISERROR(N'Học kỳ phải trong khoảng 1-3', 16, 1);
        RETURN;
    END;

    -- Kiểm tra unique NIENKHOA+HOCKY+MAMH+NHOM
    IF EXISTS (SELECT 1 FROM dbo.LOPTINCHI WHERE NIENKHOA=@NIENKHOA AND HOCKY=@HOCKY AND MAMH=@MAMH AND NHOM=@NHOM AND (@ACTION='INSERT' OR MALTC<>@MALTC))
    BEGIN
        RAISERROR(N'Lớp tín chỉ đã tồn tại với Niên khóa, Học kỳ, Môn học và Nhóm này', 16, 1);
        RETURN;
    END;

    IF UPPER(@ACTION)='INSERT'
    BEGIN
        INSERT INTO dbo.LOPTINCHI (NIENKHOA, HOCKY, MAMH, NHOM, MAGV, MAKHOA, SOSVTOITHIEU, HUYLOP)
        VALUES (@NIENKHOA, @HOCKY, @MAMH, @NHOM, @MAGV, @MAKHOA, @SOSVTOITHIEU, 0);
        SET @MALTC = SCOPE_IDENTITY();
    END
    ELSE IF UPPER(@ACTION)='UPDATE'
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM dbo.LOPTINCHI WHERE MALTC=@MALTC)
        BEGIN
            RAISERROR(N'Mã lớp tín chỉ không tồn tại', 16, 1);
            RETURN;
        END;

        UPDATE dbo.LOPTINCHI
        SET NIENKHOA     = @NIENKHOA,
            HOCKY        = @HOCKY,
            MAMH         = @MAMH,
            NHOM         = @NHOM,
            MAGV         = @MAGV,
            MAKHOA       = @MAKHOA,
            SOSVTOITHIEU = @SOSVTOITHIEU
        WHERE MALTC = @MALTC;
    END
    ELSE
    BEGIN
        RAISERROR(N'@ACTION chỉ nhận INSERT hoặc UPDATE',16,1);
    END;
END;
GO

/*
===========================================================
  SP_LTC_Cancel – Hủy lớp tín chỉ (Xóa mềm)
  Parameters: @MALTC INT
  Rules     :
      - Không hủy lớp quá khứ
===========================================================
*/
CREATE OR ALTER PROCEDURE dbo.SP_LTC_Cancel
    @MALTC INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NIENKHOA NCHAR(9), @HOCKY INT;
    SELECT @NIENKHOA=NIENKHOA, @HOCKY=HOCKY FROM dbo.LOPTINCHI WHERE MALTC=@MALTC;
    IF @NIENKHOA IS NULL
    BEGIN
        RAISERROR(N'Mã lớp tín chỉ không tồn tại', 16, 1);
        RETURN;
    END;

    IF dbo.FN_IsSemesterPast(@NIENKHOA, @HOCKY)=1
    BEGIN
        RAISERROR(N'Không được phép hủy lớp tín chỉ trong quá khứ', 16, 1);
        RETURN;
    END;

    UPDATE dbo.LOPTINCHI SET HUYLOP=1 WHERE MALTC=@MALTC;
END;
GO

/*
===========================================================
  SP_LTC_Restore – Phục hồi lớp đã hủy
===========================================================
*/
CREATE OR ALTER PROCEDURE dbo.SP_LTC_Restore
    @MALTC INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NIENKHOA NCHAR(9), @HOCKY INT;
    SELECT @NIENKHOA=NIENKHOA, @HOCKY=HOCKY FROM dbo.LOPTINCHI WHERE MALTC=@MALTC;
    IF @NIENKHOA IS NULL
    BEGIN
        RAISERROR(N'Mã lớp tín chỉ không tồn tại', 16, 1);
        RETURN;
    END;

    IF dbo.FN_IsSemesterPast(@NIENKHOA, @HOCKY)=1
    BEGIN
        RAISERROR(N'Không được phép phục hồi lớp tín chỉ trong quá khứ', 16, 1);
        RETURN;
    END;

    UPDATE dbo.LOPTINCHI SET HUYLOP=0 WHERE MALTC=@MALTC;
END;
GO

/*
===========================================================
  SP_LTC_Select
  Purpose   : Lấy danh sách lớp tín chỉ kèm thông tin thân thiện
  Parameters: @NIENKHOA NCHAR(9) = NULL
              @HOCKY    INT       = NULL
              @MAKHOA   NCHAR(10) = NULL
              @ONLY_AVAILABLE BIT = 0 (1 → chỉ lấy lớp chưa hủy)
===========================================================
*/
CREATE OR ALTER PROCEDURE dbo.SP_LTC_Select
    @NIENKHOA       NCHAR(9)  = NULL,
    @HOCKY          INT       = NULL,
    @MAKHOA         NCHAR(10) = NULL,
    @ONLY_AVAILABLE BIT       = 0
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        ltc.MALTC,
        ltc.NIENKHOA,
        ltc.HOCKY,
        ltc.NHOM,
        ltc.SOSVTOITHIEU,
        ltc.HUYLOP,
        mh.MAMH,
        mh.TENMH,
        gv.MAGV,
        (gv.HO + ' ' + gv.TEN) AS HOTENGV,
        k.MAKHOA,
        k.TENKHOA,
        (SELECT COUNT(*) FROM dbo.DANGKY dk WHERE dk.MALTC = ltc.MALTC AND dk.HUYDANGKY = 0) AS SOSVDANGKY
    FROM dbo.LOPTINCHI ltc
    INNER JOIN dbo.MONHOC  mh ON mh.MAMH = ltc.MAMH
    INNER JOIN dbo.GIANGVIEN gv ON gv.MAGV = ltc.MAGV
    INNER JOIN dbo.KHOA      k ON k.MAKHOA = ltc.MAKHOA
    WHERE (@NIENKHOA IS NULL OR ltc.NIENKHOA = @NIENKHOA)
      AND (@HOCKY   IS NULL OR ltc.HOCKY   = @HOCKY)
      AND (@MAKHOA  IS NULL OR ltc.MAKHOA  = @MAKHOA)
      AND (@ONLY_AVAILABLE = 0 OR ltc.HUYLOP = 0)
    ORDER BY mh.TENMH, ltc.NHOM;
END;
GO

/*
===========================================================
  SP_DK_Register – Đăng ký lớp tín chỉ cho sinh viên
  Parameters: @MASV  NCHAR(10)
              @MALTC INT
===========================================================
  Rules:
    - Lớp phải chưa hủy & chưa quá khứ
    - Không đăng ký trùng
===========================================================
*/
CREATE OR ALTER PROCEDURE dbo.SP_DK_Register
    @MASV  NCHAR(10),
    @MALTC INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra sinh viên tồn tại
    IF NOT EXISTS (SELECT 1 FROM dbo.SINHVIEN WHERE MASV=@MASV AND DANGHIHOC=0)
    BEGIN
        RAISERROR(N'Sinh viên không tồn tại hoặc đã nghỉ học', 16, 1);
        RETURN;
    END;

    -- Thông tin lớp tín chỉ
    DECLARE @NIENKHOA NCHAR(9), @HOCKY INT, @HUYLOP BIT;
    SELECT @NIENKHOA=NIENKHOA, @HOCKY=HOCKY, @HUYLOP=HUYLOP FROM dbo.LOPTINCHI WHERE MALTC=@MALTC;
    IF @NIENKHOA IS NULL
    BEGIN
        RAISERROR(N'Lớp tín chỉ không tồn tại', 16, 1);
        RETURN;
    END;

    IF @HUYLOP = 1
    BEGIN
        RAISERROR(N'Lớp tín chỉ đã bị hủy', 16, 1);
        RETURN;
    END;

    IF dbo.FN_IsSemesterPast(@NIENKHOA, @HOCKY)=1
    BEGIN
        RAISERROR(N'Không thể đăng ký lớp tín chỉ trong quá khứ', 16, 1);
        RETURN;
    END;

    -- Kiểm tra trùng đăng ký cùng lớp
    IF EXISTS (SELECT 1 FROM dbo.DANGKY WHERE MASV=@MASV AND MALTC=@MALTC AND HUYDANGKY=0)
    BEGIN
        RAISERROR(N'Sinh viên đã đăng ký lớp tín chỉ này', 16, 1);
        RETURN;
    END;

    /* Kiểm tra sinh viên đã đăng ký MÔN HỌC NÀY trong cùng học kỳ chưa */
    DECLARE @SUBJECT NCHAR(10) = (SELECT MAMH FROM dbo.LOPTINCHI WHERE MALTC=@MALTC);
    IF EXISTS (
        SELECT 1
        FROM dbo.DANGKY dk
        INNER JOIN dbo.LOPTINCHI ltc2 ON ltc2.MALTC = dk.MALTC
        WHERE dk.MASV = @MASV AND dk.HUYDANGKY = 0
          AND ltc2.NIENKHOA = @NIENKHOA AND ltc2.HOCKY = @HOCKY
          AND ltc2.MAMH = @SUBJECT
    )
    BEGIN
        RAISERROR(N'Sinh viên đã đăng ký môn học này trong học kỳ hiện tại',16,1);
        RETURN;
    END;

    INSERT INTO dbo.DANGKY (MALTC, MASV, DIEM_CC, DIEM_GK, DIEM_CK, HUYDANGKY)
    VALUES (@MALTC, @MASV, NULL, NULL, NULL, 0);
END;
GO

/*
===========================================================
  SP_DK_Cancel – Hủy đăng ký của sinh viên
===========================================================
*/
CREATE OR ALTER PROCEDURE dbo.SP_DK_Cancel
    @MASV  NCHAR(10),
    @MALTC INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.DANGKY SET HUYDANGKY=1
    WHERE MASV=@MASV AND MALTC=@MALTC;
END;
GO

/*
===========================================================
  SP_DK_ListByStudent – Danh sách lớp tín chỉ sinh viên đã đăng ký
===========================================================
*/
CREATE OR ALTER PROCEDURE dbo.SP_DK_ListByStudent
    @MASV NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        dk.MALTC,
        ltc.NIENKHOA,
        ltc.HOCKY,
        mh.TENMH,
        ltc.NHOM,
        (gv.HO + ' ' + gv.TEN) AS HOTENGV,
        dk.DIEM_CC,
        dk.DIEM_GK,
        dk.DIEM_CK,
        (dk.DIEM_CC*0.1 + dk.DIEM_GK*0.3 + dk.DIEM_CK*0.6) AS DIEM_HET_MON,
        dk.HUYDANGKY
    FROM dbo.DANGKY dk
    INNER JOIN dbo.LOPTINCHI ltc ON ltc.MALTC = dk.MALTC
    INNER JOIN dbo.MONHOC mh ON mh.MAMH = ltc.MAMH
    INNER JOIN dbo.GIANGVIEN gv ON gv.MAGV = ltc.MAGV
    WHERE dk.MASV = @MASV
    ORDER BY ltc.NIENKHOA, ltc.HOCKY;
END;
GO

-- =============================================
-- Phân quyền thực thi stored procedure
-- =============================================

-- LOPTINCHI procedures - Truy vấn danh sách cho tất cả các role
GRANT EXECUTE ON dbo.SP_LTC_Select TO pgv_role, khoa_role, sv_role;
GRANT EXECUTE ON dbo.FN_IsSemesterPast TO pgv_role, khoa_role, sv_role;

-- LOPTINCHI procedures - Thêm/sửa/hủy/phục hồi chỉ dành cho PGV
GRANT EXECUTE ON dbo.SP_LTC_Upsert TO pgv_role;
GRANT EXECUTE ON dbo.SP_LTC_Cancel TO pgv_role;
GRANT EXECUTE ON dbo.SP_LTC_Restore TO pgv_role;

-- DANGKY procedures - Đăng ký/hủy đăng ký cho PGV và SV
GRANT EXECUTE ON dbo.SP_DK_Register TO pgv_role, sv_role;
GRANT EXECUTE ON dbo.SP_DK_Cancel TO pgv_role, sv_role;

-- DANGKY procedures - Xem danh sách đăng ký cho tất cả các role
GRANT EXECUTE ON dbo.SP_DK_ListByStudent TO pgv_role, khoa_role, sv_role;
GO 