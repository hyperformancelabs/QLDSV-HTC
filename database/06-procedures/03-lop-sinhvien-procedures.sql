/*
===========================================================
  File        : 03-lop-sinhvien-procedures.sql
  Description : Stored procedures CRUD cho LOP & SINHVIEN
===========================================================
*/

USE [$(DB_NAME)];
GO

/*
===========================================================
  BẢNG LOP
===========================================================
*/
/*
===========================================================
  SP_LOP_SelectByKhoa
  Purpose   : Lấy danh sách lớp theo mã khoa (PGV/KHOA)
  Parameters: @MAKHOA   - NCHAR(10) (NULL → lấy tất cả)
              @KHOAHOC  - NCHAR(9)  (NULL → lấy tất cả)
===========================================================
*/
CREATE OR ALTER PROCEDURE dbo.SP_LOP_SelectByKhoa
    @MAKHOA  NCHAR(10) = NULL,
    @KHOAHOC NCHAR(9) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        MALOP,
        TENLOP,
        KHOAHOC,
        MAKHOA,
        TENKHOA,
        SOSINHVIEN
    FROM dbo.V_LOP_WithStudentCount WITH (NOLOCK)
    WHERE (@MAKHOA IS NULL OR MAKHOA = @MAKHOA)
      AND (@KHOAHOC IS NULL OR KHOAHOC = @KHOAHOC)
    ORDER BY TENLOP;
END;
GO

/*
===========================================================
  SP_LOP_HasStudents
  Purpose   : Kiểm tra xem lớp có sinh viên không
  Parameters: @MALOP  - NCHAR(10)
  Returns   : Số lượng sinh viên trong lớp
===========================================================
*/
CREATE OR ALTER PROCEDURE dbo.SP_LOP_HasStudents
    @MALOP NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT COUNT(*) AS StudentCount
    FROM dbo.SINHVIEN WITH (NOLOCK)
    WHERE MALOP = @MALOP;
END;
GO

/*
===========================================================
  SP_LOP_Upsert
  Purpose   : Thêm mới / cập nhật lớp
  Rules     : - TENLOP duy nhất trong toàn bộ bảng
===========================================================
*/
CREATE OR ALTER PROCEDURE dbo.SP_LOP_Upsert
    @MALOP   NCHAR(10),
    @TENLOP  NVARCHAR(50),
    @KHOAHOC NVARCHAR(9), -- vd: 2021-2025
    @MAKHOA  NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate TENLOP duy nhất
    IF EXISTS (SELECT 1 FROM dbo.LOP WHERE TENLOP = @TENLOP AND MALOP <> @MALOP)
    BEGIN
        RAISERROR(N'Tên lớp đã tồn tại', 16, 1);
        RETURN;
    END;

    IF EXISTS (SELECT 1 FROM dbo.LOP WHERE MALOP = @MALOP)
    BEGIN
        UPDATE dbo.LOP
        SET TENLOP  = @TENLOP,
            KHOAHOC = @KHOAHOC,
            MAKHOA  = @MAKHOA
        WHERE MALOP = @MALOP;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.LOP (MALOP, TENLOP, KHOAHOC, MAKHOA)
        VALUES (@MALOP, @TENLOP, @KHOAHOC, @MAKHOA);
    END;
END;
GO

/*
===========================================================
  SP_LOP_Delete
  Purpose   : Xóa lớp nếu không có sinh viên thuộc lớp
===========================================================
*/
CREATE OR ALTER PROCEDURE dbo.SP_LOP_Delete
    @MALOP NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.LOP WHERE MALOP = @MALOP)
    BEGIN
        RAISERROR(N'Mã lớp không tồn tại', 16, 1);
        RETURN;
    END;

    IF EXISTS (SELECT 1 FROM dbo.SINHVIEN WHERE MALOP = @MALOP)
    BEGIN
        RAISERROR(N'Không thể xóa lớp vì đã có sinh viên', 16, 1);
        RETURN;
    END;

    DELETE FROM dbo.LOP WHERE MALOP = @MALOP;
END;
GO

/*
===========================================================
                    BẢNG SINHVIEN                          
===========================================================
 */
/*
===========================================================
  SP_SV_SelectByClass
  Purpose   : Lấy danh sách sinh viên theo lớp kèm phân trang, tìm kiếm
  Parameters: @MALOP     NCHAR(10)
              @PAGE      INT (>=1)
              @PAGESIZE  INT (>=1)
              @SEARCH    NVARCHAR(100) (NULL → không lọc)
              @SORTBY    NVARCHAR(30) - chỉ chấp nhận cột hợp lệ
              @SORTDIR   NVARCHAR(4)  - 'ASC' | 'DESC'
===========================================================
*/
CREATE OR ALTER PROCEDURE dbo.SP_SV_SelectByClass
    @MALOP     NCHAR(10),
    @PAGE      INT           = 1,
    @PAGESIZE  INT           = 50,
    @SEARCH    NVARCHAR(100) = NULL,
    @SORTBY    NVARCHAR(30)  = N'HO',
    @SORTDIR   NVARCHAR(4)   = N'ASC'
AS
BEGIN
    SET NOCOUNT ON;

    IF @PAGE < 1 SET @PAGE = 1;
    IF @PAGESIZE < 1 SET @PAGESIZE = 50;

    DECLARE @Offset INT = (@PAGE - 1) * @PAGESIZE;
    DECLARE @SearchPattern NVARCHAR(110) = CASE WHEN @SEARCH IS NULL OR @SEARCH = N'' THEN NULL ELSE @SEARCH + N'%' END;

    -- Validate sort column and direction
    IF @SORTBY NOT IN (N'HO', N'TEN', N'MASV', N'PHAI', N'NGAYSINH')
        SET @SORTBY = N'HO';
    
    IF UPPER(@SORTDIR) NOT IN ('ASC','DESC') 
        SET @SORTDIR = N'ASC';

    -- Sử dụng CASE để thay thế dynamic SQL
    IF UPPER(@SORTDIR) = 'ASC'
    BEGIN
        IF @SORTBY = N'HO'
        BEGIN
            SELECT MASV, HO, TEN, PHAI, NGAYSINH, DIACHI, DANGHIHOC, MALOP
            FROM dbo.SINHVIEN WITH (NOLOCK)
            WHERE MALOP = @MALOP
              AND (@SearchPattern IS NULL OR MASV LIKE @SearchPattern OR HO + ' ' + TEN LIKE @SearchPattern)
            ORDER BY HO ASC
            OFFSET @Offset ROWS FETCH NEXT @PAGESIZE ROWS ONLY;
        END
        ELSE IF @SORTBY = N'TEN'
        BEGIN
            SELECT MASV, HO, TEN, PHAI, NGAYSINH, DIACHI, DANGHIHOC, MALOP
            FROM dbo.SINHVIEN WITH (NOLOCK)
            WHERE MALOP = @MALOP
              AND (@SearchPattern IS NULL OR MASV LIKE @SearchPattern OR HO + ' ' + TEN LIKE @SearchPattern)
            ORDER BY TEN ASC
            OFFSET @Offset ROWS FETCH NEXT @PAGESIZE ROWS ONLY;
        END
        ELSE IF @SORTBY = N'MASV'
        BEGIN
            SELECT MASV, HO, TEN, PHAI, NGAYSINH, DIACHI, DANGHIHOC, MALOP
            FROM dbo.SINHVIEN WITH (NOLOCK)
            WHERE MALOP = @MALOP
              AND (@SearchPattern IS NULL OR MASV LIKE @SearchPattern OR HO + ' ' + TEN LIKE @SearchPattern)
            ORDER BY MASV ASC
            OFFSET @Offset ROWS FETCH NEXT @PAGESIZE ROWS ONLY;
        END
        ELSE IF @SORTBY = N'PHAI'
        BEGIN
            SELECT MASV, HO, TEN, PHAI, NGAYSINH, DIACHI, DANGHIHOC, MALOP
            FROM dbo.SINHVIEN WITH (NOLOCK)
            WHERE MALOP = @MALOP
              AND (@SearchPattern IS NULL OR MASV LIKE @SearchPattern OR HO + ' ' + TEN LIKE @SearchPattern)
            ORDER BY PHAI ASC
            OFFSET @Offset ROWS FETCH NEXT @PAGESIZE ROWS ONLY;
        END
        ELSE IF @SORTBY = N'NGAYSINH'
        BEGIN
            SELECT MASV, HO, TEN, PHAI, NGAYSINH, DIACHI, DANGHIHOC, MALOP
            FROM dbo.SINHVIEN WITH (NOLOCK)
            WHERE MALOP = @MALOP
              AND (@SearchPattern IS NULL OR MASV LIKE @SearchPattern OR HO + ' ' + TEN LIKE @SearchPattern)
            ORDER BY NGAYSINH ASC
            OFFSET @Offset ROWS FETCH NEXT @PAGESIZE ROWS ONLY;
        END
    END
    ELSE -- DESC
    BEGIN
        IF @SORTBY = N'HO'
        BEGIN
            SELECT MASV, HO, TEN, PHAI, NGAYSINH, DIACHI, DANGHIHOC, MALOP
            FROM dbo.SINHVIEN WITH (NOLOCK)
            WHERE MALOP = @MALOP
              AND (@SearchPattern IS NULL OR MASV LIKE @SearchPattern OR HO + ' ' + TEN LIKE @SearchPattern)
            ORDER BY HO DESC
            OFFSET @Offset ROWS FETCH NEXT @PAGESIZE ROWS ONLY;
        END
        ELSE IF @SORTBY = N'TEN'
        BEGIN
            SELECT MASV, HO, TEN, PHAI, NGAYSINH, DIACHI, DANGHIHOC, MALOP
            FROM dbo.SINHVIEN WITH (NOLOCK)
            WHERE MALOP = @MALOP
              AND (@SearchPattern IS NULL OR MASV LIKE @SearchPattern OR HO + ' ' + TEN LIKE @SearchPattern)
            ORDER BY TEN DESC
            OFFSET @Offset ROWS FETCH NEXT @PAGESIZE ROWS ONLY;
        END
        ELSE IF @SORTBY = N'MASV'
        BEGIN
            SELECT MASV, HO, TEN, PHAI, NGAYSINH, DIACHI, DANGHIHOC, MALOP
            FROM dbo.SINHVIEN WITH (NOLOCK)
            WHERE MALOP = @MALOP
              AND (@SearchPattern IS NULL OR MASV LIKE @SearchPattern OR HO + ' ' + TEN LIKE @SearchPattern)
            ORDER BY MASV DESC
            OFFSET @Offset ROWS FETCH NEXT @PAGESIZE ROWS ONLY;
        END
        ELSE IF @SORTBY = N'PHAI'
        BEGIN
            SELECT MASV, HO, TEN, PHAI, NGAYSINH, DIACHI, DANGHIHOC, MALOP
            FROM dbo.SINHVIEN WITH (NOLOCK)
            WHERE MALOP = @MALOP
              AND (@SearchPattern IS NULL OR MASV LIKE @SearchPattern OR HO + ' ' + TEN LIKE @SearchPattern)
            ORDER BY PHAI DESC
            OFFSET @Offset ROWS FETCH NEXT @PAGESIZE ROWS ONLY;
        END
        ELSE IF @SORTBY = N'NGAYSINH'
        BEGIN
            SELECT MASV, HO, TEN, PHAI, NGAYSINH, DIACHI, DANGHIHOC, MALOP
            FROM dbo.SINHVIEN WITH (NOLOCK)
            WHERE MALOP = @MALOP
              AND (@SearchPattern IS NULL OR MASV LIKE @SearchPattern OR HO + ' ' + TEN LIKE @SearchPattern)
            ORDER BY NGAYSINH DESC
            OFFSET @Offset ROWS FETCH NEXT @PAGESIZE ROWS ONLY;
        END
    END

    -- Trả về thêm tổng số bản ghi để FE paging
    SELECT TotalCount = COUNT(*)
    FROM   dbo.SINHVIEN WITH (NOLOCK)
    WHERE  MALOP = @MALOP
       AND (@SearchPattern IS NULL OR MASV LIKE @SearchPattern OR HO + ' ' + TEN LIKE @SearchPattern);
END;
GO

/*
===========================================================
  SP_SV_Upsert
  Purpose   : Thêm mới / cập nhật sinh viên
===========================================================
*/
CREATE OR ALTER PROCEDURE dbo.SP_SV_Upsert
    @MASV      NCHAR(10),
    @HO        NVARCHAR(50),
    @TEN       NVARCHAR(10),
    @MALOP     NCHAR(10),
    @PHAI      BIT,  -- Changed from NCHAR(3) to BIT (0=Nam, 1=Nữ)
    @NGAYSINH  DATE,
    @DIACHI    NVARCHAR(100),
    @DANGHIHOC BIT = 0,
    @PASSWORD  NVARCHAR(64) -- đã băm SHA2_256 ở tầng ứng dụng
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra lớp tồn tại
    IF NOT EXISTS (SELECT 1 FROM dbo.LOP WHERE MALOP = @MALOP)
    BEGIN
        RAISERROR(N'Lớp không tồn tại', 16, 1);
        RETURN;
    END;

    IF EXISTS (SELECT 1 FROM dbo.SINHVIEN WHERE MASV = @MASV)
    BEGIN
        UPDATE dbo.SINHVIEN
        SET HO        = @HO,
            TEN       = @TEN,
            MALOP     = @MALOP,
            PHAI      = @PHAI,
            NGAYSINH  = @NGAYSINH,
            DIACHI    = @DIACHI,
            DANGHIHOC = @DANGHIHOC,
            PASSWORD  = @PASSWORD
        WHERE MASV = @MASV;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.SINHVIEN (MASV, HO, TEN, MALOP, PHAI, NGAYSINH, DIACHI, DANGHIHOC, PASSWORD)
        VALUES (@MASV, @HO, @TEN, @MALOP, @PHAI, @NGAYSINH, @DIACHI, @DANGHIHOC, @PASSWORD);
    END;
END;
GO

/*
===========================================================
  SP_SV_Delete
  Purpose   : Xoá sinh viên (hard delete)
===========================================================
*/
CREATE OR ALTER PROCEDURE dbo.SP_SV_Delete
    @MASV NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.SINHVIEN WHERE MASV = @MASV)
    BEGIN
        RAISERROR(N'Mã sinh viên không tồn tại', 16, 1);
        RETURN;
    END;

    DELETE FROM dbo.SINHVIEN WHERE MASV = @MASV;
END;
GO

-- Phân quyền
GRANT EXECUTE ON dbo.SP_LOP_SelectByKhoa TO pgv_role, khoa_role;
GRANT EXECUTE ON dbo.SP_LOP_Upsert      TO pgv_role;
GRANT EXECUTE ON dbo.SP_LOP_Delete      TO pgv_role;

GRANT EXECUTE ON dbo.SP_SV_SelectByClass TO pgv_role, khoa_role;
GRANT EXECUTE ON dbo.SP_SV_Upsert        TO pgv_role;
GRANT EXECUTE ON dbo.SP_SV_Delete        TO pgv_role;
GO 