-- Stored procedures for MONHOC (môn học)
-- Applies to $(DB_NAME)

USE [$(DB_NAME)];
GO

/*===========================================================
  SP_MonHoc_Select
  Purpose   : Trả về danh sách môn học (toàn bộ hoặc theo bộ lọc)
  Parameters: @MAMH  - NCHAR(10)  (NULL  : không lọc theo mã)
              @TENMH - NVARCHAR(50) (NULL: không lọc theo tên, hỗ trợ LIKE)
  Notes     : Quyền truy cập do tầng ứng dụng kiểm soát (chỉ PGV)
===========================================================*/
CREATE OR ALTER PROCEDURE dbo.SP_MonHoc_Select
    @MAMH  NCHAR(10)   = NULL,
    @TENMH NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Xử lý pattern tìm kiếm tên môn học.
    DECLARE @Pattern NVARCHAR(60);
    IF @TENMH IS NULL OR @TENMH = N''
        SET @Pattern = NULL;
    ELSE IF CHARINDEX(N'%', @TENMH) > 0 -- Caller đã tự truyền wildcard
        SET @Pattern = @TENMH;
    ELSE
        -- Sử dụng tìm kiếm theo tiền tố để tận dụng index trên TENMH
        SET @Pattern = @TENMH + N'%';

    SELECT  m.MAMH,
            m.TENMH,
            m.SOTIET_LT,
            m.SOTIET_TH,
            CAST(CASE WHEN EXISTS (SELECT 1 FROM LOPTINCHI ltc WHERE ltc.MAMH = m.MAMH) 
                  THEN 1 ELSE 0 END AS BIT) AS IS_LINKED
    FROM    MONHOC m WITH (NOLOCK)
    WHERE   (@MAMH  IS NULL OR m.MAMH = @MAMH)
      AND   (@Pattern IS NULL OR m.TENMH LIKE @Pattern)
    OPTION (RECOMPILE); -- tránh parameter sniffing, chọn plan tối ưu theo pattern
END;
GO

/*===========================================================
  SP_MonHoc_Upsert
  Purpose   : Thêm mới hoặc cập nhật thông tin môn học
  Parameters: @MAMH      - NCHAR(10) (PK)
              @TENMH     - NVARCHAR(50) (Tên môn học – Unique)
              @SOTIET_LT - INT >= 0
              @SOTIET_TH - INT >= 0
  Rules     :
      1. Nếu MAMH chưa tồn tại -> INSERT
      2. Nếu MAMH đã tồn tại -> UPDATE
      3. TENMH phải duy nhất (ngoại trừ bản ghi đang UPDATE chính nó)
===========================================================*/
CREATE OR ALTER PROCEDURE dbo.SP_MonHoc_Upsert
    @MAMH      NCHAR(10),
    @TENMH     NVARCHAR(50),
    @SOTIET_LT INT,
    @SOTIET_TH INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate input
    IF @SOTIET_LT < 0 OR @SOTIET_TH < 0
    BEGIN
        RAISERROR(N'Số tiết phải >= 0', 16, 1);
        RETURN;
    END;

    -- Kiểm tra trùng TENMH (không tính bản ghi hiện tại khi update)
    IF EXISTS (SELECT 1 FROM MONHOC WHERE TENMH = @TENMH AND MAMH <> @MAMH)
    BEGIN
        RAISERROR(N'Tên môn học đã tồn tại', 16, 1);
        RETURN;
    END;

    -- Upsert logic
    IF EXISTS (SELECT 1 FROM MONHOC WHERE MAMH = @MAMH)
    BEGIN
        -- UPDATE
        UPDATE MONHOC
        SET TENMH     = @TENMH,
            SOTIET_LT = @SOTIET_LT,
            SOTIET_TH = @SOTIET_TH
        WHERE MAMH = @MAMH;
    END
    ELSE
    BEGIN
        -- INSERT
        INSERT INTO MONHOC (MAMH, TENMH, SOTIET_LT, SOTIET_TH)
        VALUES (@MAMH, @TENMH, @SOTIET_LT, @SOTIET_TH);
    END;
END;
GO

/*===========================================================
  SP_MonHoc_Delete
  Purpose   : Xóa môn học (hard delete) - chỉ khi chưa được tham chiếu
  Parameters: @MAMH - NCHAR(10)
  Rules     :
      • Không cho xóa nếu tồn tại LOPTINCHI tham chiếu.
===========================================================*/
CREATE OR ALTER PROCEDURE dbo.SP_MonHoc_Delete
    @MAMH NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra tồn tại
    IF NOT EXISTS (SELECT 1 FROM MONHOC WHERE MAMH = @MAMH)
    BEGIN
        RAISERROR(N'Mã môn học không tồn tại', 16, 1);
        RETURN;
    END;

    -- Kiểm tra ràng buộc FK
    IF EXISTS (SELECT 1 FROM LOPTINCHI WHERE MAMH = @MAMH)
    BEGIN
        RAISERROR(N'Môn học đã/đang được mở lớp tín chỉ - không thể xóa', 16, 1);
        RETURN;
    END;

    DELETE FROM MONHOC WHERE MAMH = @MAMH;
END;
GO 

GRANT EXECUTE ON dbo.SP_MonHoc_Select TO khoa_role;