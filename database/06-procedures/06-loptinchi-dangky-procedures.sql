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

/*
===========================================================
  SP_DK_Reregister – Đăng ký lại lớp đã hủy đăng ký
  Parameters: @MASV  NCHAR(10)
              @MALTC INT
===========================================================
  Rules:
    - Lớp phải chưa hủy & chưa quá khứ
    - Bản ghi đăng ký đã tồn tại và đã hủy (HUYDANGKY=1)
===========================================================
*/
CREATE OR ALTER PROCEDURE dbo.SP_DK_Reregister
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

    -- Kiểm tra bản ghi đăng ký đã tồn tại và đã hủy
    IF NOT EXISTS (SELECT 1 FROM dbo.DANGKY WHERE MASV=@MASV AND MALTC=@MALTC AND HUYDANGKY=1)
    BEGIN
        RAISERROR(N'Không tìm thấy bản ghi đăng ký đã hủy để đăng ký lại', 16, 1);
        RETURN;
    END;

    -- Cập nhật bản ghi đăng ký đã hủy thành đăng ký lại
    UPDATE dbo.DANGKY SET 
        HUYDANGKY = 0,
        DIEM_CC = NULL,
        DIEM_GK = NULL,
        DIEM_CK = NULL
    WHERE MASV=@MASV AND MALTC=@MALTC;
END;
GO

/*
===========================================================
  SP_DK_GetStudentsForGrading – Get students for grade input
  Purpose   : Lấy danh sách sinh viên đã đăng ký lớp tín chỉ để nhập điểm
  Parameters: @NIENKHOA NCHAR(9)
              @HOCKY    INT
              @MAMH     NCHAR(10)
              @NHOM     INT
===========================================================
*/
CREATE OR ALTER PROCEDURE dbo.SP_DK_GetStudentsForGrading
    @NIENKHOA NCHAR(9),
    @HOCKY    INT,
    @MAMH     NCHAR(10),
    @NHOM     INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Lấy thông tin sinh viên đã đăng ký lớp
    SELECT 
        sv.MASV,
        sv.HO,
        sv.TEN,
        dk.DIEM_CC,
        dk.DIEM_GK,
        dk.DIEM_CK,
        CONVERT(FLOAT, CASE 
            WHEN dk.DIEM_CC IS NULL OR dk.DIEM_GK IS NULL OR dk.DIEM_CK IS NULL THEN NULL
            ELSE ROUND(dk.DIEM_CC*0.1 + dk.DIEM_GK*0.3 + dk.DIEM_CK*0.6, 1)
        END) AS DIEM_HET_MON,
        ltc.MALTC
    FROM dbo.LOPTINCHI ltc
    INNER JOIN dbo.DANGKY dk ON ltc.MALTC = dk.MALTC
    INNER JOIN dbo.SINHVIEN sv ON dk.MASV = sv.MASV
    WHERE ltc.NIENKHOA = @NIENKHOA
      AND ltc.HOCKY = @HOCKY
      AND ltc.MAMH = @MAMH
      AND ltc.NHOM = @NHOM
      AND dk.HUYDANGKY = 0
    ORDER BY sv.TEN, sv.HO;
END;
GO

/*
===========================================================
  SP_DK_SaveGrades – Save student grades
  Purpose   : Lưu điểm sinh viên vào CSDL
  Parameters: @MALTC    INT
              @MASV     NCHAR(10)
              @DIEM_CC  INT
              @DIEM_GK  FLOAT
              @DIEM_CK  FLOAT
===========================================================
*/
CREATE OR ALTER PROCEDURE dbo.SP_DK_SaveGrades
    @MALTC    INT,
    @MASV     NCHAR(10),
    @DIEM_CC  INT = NULL,
    @DIEM_GK  FLOAT = NULL,
    @DIEM_CK  FLOAT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validate điểm
    IF @DIEM_CC IS NOT NULL AND (@DIEM_CC < 0 OR @DIEM_CC > 10)
    BEGIN
        RAISERROR(N'Điểm chuyên cần phải từ 0 đến 10', 16, 1);
        RETURN;
    END;
    
    IF @DIEM_GK IS NOT NULL AND (@DIEM_GK < 0 OR @DIEM_GK > 10)
    BEGIN
        RAISERROR(N'Điểm giữa kỳ phải từ 0 đến 10', 16, 1);
        RETURN;
    END;
    
    IF @DIEM_CK IS NOT NULL AND (@DIEM_CK < 0 OR @DIEM_CK > 10)
    BEGIN
        RAISERROR(N'Điểm cuối kỳ phải từ 0 đến 10', 16, 1);
        RETURN;
    END;

    -- Làm tròn điểm đến 0.5 theo yêu cầu của schema
    IF @DIEM_GK IS NOT NULL
        SET @DIEM_GK = ROUND(@DIEM_GK * 2, 0) / 2;
    
    IF @DIEM_CK IS NOT NULL
        SET @DIEM_CK = ROUND(@DIEM_CK * 2, 0) / 2;
    
    -- Cập nhật điểm
    UPDATE dbo.DANGKY
    SET DIEM_CC = @DIEM_CC,
        DIEM_GK = @DIEM_GK,
        DIEM_CK = @DIEM_CK
    WHERE MALTC = @MALTC AND MASV = @MASV;
    
    IF @@ROWCOUNT = 0
    BEGIN
        RAISERROR(N'Không tìm thấy bản ghi đăng ký cho sinh viên %s và lớp tín chỉ %d', 16, 1, @MASV, @MALTC);
    END;
END;
GO

/*
===========================================================
  SP_DK_SaveMultipleGrades – Save grades for multiple students
  Purpose   : Lưu điểm cho nhiều sinh viên cùng lúc
  Parameters: @MALTC    INT
              @MASV_LIST        NVARCHAR(MAX) - Danh sách mã sinh viên, phân cách bởi dấu ','
              @DIEM_CC_LIST     NVARCHAR(MAX) - Danh sách điểm chuyên cần, phân cách bởi dấu ','
              @DIEM_GK_LIST     NVARCHAR(MAX) - Danh sách điểm giữa kỳ, phân cách bởi dấu ','
              @DIEM_CK_LIST     NVARCHAR(MAX) - Danh sách điểm cuối kỳ, phân cách bởi dấu ','
===========================================================
*/
CREATE OR ALTER PROCEDURE dbo.SP_DK_SaveMultipleGrades
    @MALTC           INT,
    @MASV_LIST       NVARCHAR(MAX),
    @DIEM_CC_LIST    NVARCHAR(MAX),
    @DIEM_GK_LIST    NVARCHAR(MAX),
    @DIEM_CK_LIST    NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Tạo bảng tạm để lưu trữ dữ liệu
    CREATE TABLE #TempGrades (
        MASV     NCHAR(10),
        DIEM_CC  INT,
        DIEM_GK  FLOAT,
        DIEM_CK  FLOAT
    );

    -- Biến để duyệt qua các danh sách
    DECLARE @POS_MASV INT = 1;
    DECLARE @POS_CC INT = 1;
    DECLARE @POS_GK INT = 1;
    DECLARE @POS_CK INT = 1;
    DECLARE @NEXT_POS_MASV INT;
    DECLARE @NEXT_POS_CC INT;
    DECLARE @NEXT_POS_GK INT;
    DECLARE @NEXT_POS_CK INT;
    DECLARE @MASV NCHAR(10);
    DECLARE @DIEM_CC_STR NVARCHAR(10);
    DECLARE @DIEM_GK_STR NVARCHAR(10);
    DECLARE @DIEM_CK_STR NVARCHAR(10);
    DECLARE @DIEM_CC INT;
    DECLARE @DIEM_GK FLOAT;
    DECLARE @DIEM_CK FLOAT;

    -- Parse danh sách MASV và điểm
    WHILE @POS_MASV <= LEN(@MASV_LIST)
    BEGIN
        -- Parse MASV
        SET @NEXT_POS_MASV = CHARINDEX(',', @MASV_LIST, @POS_MASV);
        IF @NEXT_POS_MASV = 0 SET @NEXT_POS_MASV = LEN(@MASV_LIST) + 1;
        SET @MASV = RTRIM(LTRIM(SUBSTRING(@MASV_LIST, @POS_MASV, @NEXT_POS_MASV - @POS_MASV)));
        SET @POS_MASV = @NEXT_POS_MASV + 1;

        -- Parse DIEM_CC
        SET @NEXT_POS_CC = CHARINDEX(',', @DIEM_CC_LIST, @POS_CC);
        IF @NEXT_POS_CC = 0 SET @NEXT_POS_CC = LEN(@DIEM_CC_LIST) + 1;
        SET @DIEM_CC_STR = RTRIM(LTRIM(SUBSTRING(@DIEM_CC_LIST, @POS_CC, @NEXT_POS_CC - @POS_CC)));
        SET @DIEM_CC = CASE WHEN @DIEM_CC_STR = 'NULL' OR @DIEM_CC_STR = '' THEN NULL ELSE CAST(@DIEM_CC_STR AS INT) END;
        SET @POS_CC = @NEXT_POS_CC + 1;

        -- Parse DIEM_GK
        SET @NEXT_POS_GK = CHARINDEX(',', @DIEM_GK_LIST, @POS_GK);
        IF @NEXT_POS_GK = 0 SET @NEXT_POS_GK = LEN(@DIEM_GK_LIST) + 1;
        SET @DIEM_GK_STR = RTRIM(LTRIM(SUBSTRING(@DIEM_GK_LIST, @POS_GK, @NEXT_POS_GK - @POS_GK)));
        SET @DIEM_GK = CASE WHEN @DIEM_GK_STR = 'NULL' OR @DIEM_GK_STR = '' THEN NULL ELSE CAST(@DIEM_GK_STR AS FLOAT) END;
        SET @POS_GK = @NEXT_POS_GK + 1;

        -- Parse DIEM_CK
        SET @NEXT_POS_CK = CHARINDEX(',', @DIEM_CK_LIST, @POS_CK);
        IF @NEXT_POS_CK = 0 SET @NEXT_POS_CK = LEN(@DIEM_CK_LIST) + 1;
        SET @DIEM_CK_STR = RTRIM(LTRIM(SUBSTRING(@DIEM_CK_LIST, @POS_CK, @NEXT_POS_CK - @POS_CK)));
        SET @DIEM_CK = CASE WHEN @DIEM_CK_STR = 'NULL' OR @DIEM_CK_STR = '' THEN NULL ELSE CAST(@DIEM_CK_STR AS FLOAT) END;
        SET @POS_CK = @NEXT_POS_CK + 1;

        -- Validate điểm
        IF @DIEM_CC IS NOT NULL AND (@DIEM_CC < 0 OR @DIEM_CC > 10)
        BEGIN
            RAISERROR(N'Điểm chuyên cần của sinh viên %s phải từ 0 đến 10', 16, 1, @MASV);
            DROP TABLE #TempGrades;
            RETURN;
        END;

        IF @DIEM_GK IS NOT NULL AND (@DIEM_GK < 0 OR @DIEM_GK > 10)
        BEGIN
            RAISERROR(N'Điểm giữa kỳ của sinh viên %s phải từ 0 đến 10', 16, 1, @MASV);
            DROP TABLE #TempGrades;
            RETURN;
        END;

        IF @DIEM_CK IS NOT NULL AND (@DIEM_CK < 0 OR @DIEM_CK > 10)
        BEGIN
            RAISERROR(N'Điểm cuối kỳ của sinh viên %s phải từ 0 đến 10', 16, 1, @MASV);
            DROP TABLE #TempGrades;
            RETURN;
        END;

        -- Làm tròn điểm đến 0.5 theo yêu cầu của schema
        IF @DIEM_GK IS NOT NULL
            SET @DIEM_GK = ROUND(@DIEM_GK * 2, 0) / 2;
        
        IF @DIEM_CK IS NOT NULL
            SET @DIEM_CK = ROUND(@DIEM_CK * 2, 0) / 2;

        -- Thêm vào bảng tạm
        INSERT INTO #TempGrades (MASV, DIEM_CC, DIEM_GK, DIEM_CK)
        VALUES (@MASV, @DIEM_CC, @DIEM_GK, @DIEM_CK);
    END;

    -- Cập nhật điểm từ bảng tạm vào DANGKY
    UPDATE dk
    SET dk.DIEM_CC = t.DIEM_CC,
        dk.DIEM_GK = t.DIEM_GK,
        dk.DIEM_CK = t.DIEM_CK
    FROM dbo.DANGKY dk
    INNER JOIN #TempGrades t ON dk.MASV = t.MASV
    WHERE dk.MALTC = @MALTC;

    -- Xóa bảng tạm
    DROP TABLE #TempGrades;
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
GRANT EXECUTE ON dbo.SP_DK_Reregister TO pgv_role, sv_role;

-- DANGKY procedures - Xem danh sách đăng ký cho tất cả các role
GRANT EXECUTE ON dbo.SP_DK_ListByStudent TO pgv_role, khoa_role, sv_role;

-- Phân quyền thực thi stored procedure
GRANT EXECUTE ON dbo.SP_DK_GetStudentsForGrading TO pgv_role, khoa_role;
GRANT EXECUTE ON dbo.SP_DK_SaveGrades TO pgv_role, khoa_role;
GRANT EXECUTE ON dbo.SP_DK_SaveMultipleGrades TO pgv_role, khoa_role;
GO 