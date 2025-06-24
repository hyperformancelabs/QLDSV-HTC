USE [$(DB_NAME)];
GO

-- =============================================
-- Description: Thêm giảng viên mới và tạo tài khoản đăng nhập
-- Parameters:  @LOGINNAME - Tên đăng nhập SQL Server
--              @MAGV - Mã giảng viên (sẽ là tên USER trong DB)
--              @HO - Họ giảng viên
--              @TEN - Tên giảng viên
--              @MAKHOA - Mã khoa
--              @ROLE - Nhóm quyền (pgv_role/khoa_role)
--              @PASSWORD - Mật khẩu (bắt buộc)
--              @HOCVI - Học vị
--              @HOCHAM - Học hàm
--              @CHUYENMON - Chuyên môn
-- =============================================
CREATE OR ALTER PROCEDURE dbo.sp_Them_GiangVien
    @LOGINNAME SYSNAME,
    @MAGV      NCHAR(10),
    @HO        NVARCHAR(50),
    @TEN       NVARCHAR(10),
    @MAKHOA    NCHAR(10),
    @ROLE      SYSNAME,
    @PASSWORD  NVARCHAR(128),
    @HOCVI     NVARCHAR(20) = NULL,
    @HOCHAM    NVARCHAR(20) = NULL,
    @CHUYENMON NVARCHAR(50) = NULL
WITH EXECUTE AS '$(MSSQL_SUPERADMIN_USER)'
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra role hợp lệ
    IF @ROLE NOT IN (N'pgv_role', N'khoa_role')
    BEGIN
        RAISERROR(N'ROLE phải là pgv_role hoặc khoa_role', 16, 1);
        RETURN;
    END;

    -- Kiểm tra trùng mã giảng viên
    IF EXISTS (SELECT 1 FROM GIANGVIEN WHERE MAGV = @MAGV)
    BEGIN
        RAISERROR(N'Mã giảng viên đã tồn tại', 16, 1);
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Thêm giảng viên mới
        INSERT INTO GIANGVIEN (MAGV, HO, TEN, MAKHOA, HOCVI, HOCHAM, CHUYENMON)
        VALUES (@MAGV, @HO, @TEN, @MAKHOA, @HOCVI, @HOCHAM, @CHUYENMON);
        
        -- Tạo tài khoản đăng nhập cho giảng viên
        EXEC dbo.sp_Tao_Login_User_GiangVien 
            @LOGINNAME = @LOGINNAME,
            @PASSWORD = @PASSWORD,
            @MAGV = @MAGV;
            
        -- Thêm USER vào ROLE
        DECLARE @sql NVARCHAR(200) = N'ALTER ROLE ' + QUOTENAME(@ROLE) 
                + N' ADD MEMBER ' + QUOTENAME(RTRIM(@MAGV));
        EXEC (@sql);
            
        COMMIT;
        
        -- Trả về thông tin giảng viên vừa thêm
        SELECT GV.*, K.TENKHOA, 1 AS HasLogin, @ROLE AS RoleName
        FROM GIANGVIEN GV
        JOIN KHOA K ON GV.MAKHOA = K.MAKHOA
        WHERE GV.MAGV = @MAGV;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

-- =============================================
-- Description: Kiểm tra xem MAGV đã có SQL Login hay chưa
-- Parameters:  @MAGV - Mã giảng viên
-- Returns:     1 nếu đã có login, 0 nếu chưa có
-- =============================================
CREATE OR ALTER PROCEDURE dbo.sp_Check_GiangVien_HasLogin
    @MAGV NCHAR(10)
WITH EXECUTE AS '$(MSSQL_SUPERADMIN_USER)'
AS
BEGIN
    SET NOCOUNT ON;

    -- Loại bỏ khoảng trắng
    DECLARE @MAGV_CLEAN NVARCHAR(10) = RTRIM(@MAGV);
    
    -- Kiểm tra xem MAGV có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM GIANGVIEN WHERE RTRIM(MAGV) = @MAGV_CLEAN)
    BEGIN
        RAISERROR(N'Mã giảng viên không tồn tại', 16, 1);
        RETURN;
    END

    -- Kiểm tra xem MAGV đã có user trong database (không phụ thuộc vào login SID)
    IF EXISTS (
        SELECT 1 
        FROM sys.database_principals 
        WHERE name = @MAGV_CLEAN AND type = 'S'
    )
    BEGIN
        SELECT 1 AS HasLogin;
    END
    ELSE
    BEGIN
        SELECT 0 AS HasLogin;
    END
END;
GO

-- =============================================
-- Description: Tạo view hiển thị thông tin giảng viên kèm trạng thái login
-- =============================================
-- Directly modify this view to use correct login detection
CREATE OR ALTER VIEW dbo.V_GIANGVIEN_WITH_LOGIN 
AS
SELECT 
    RTRIM(GV.MAGV) AS MAGV, GV.HO, GV.TEN, GV.HOCVI, GV.HOCHAM, GV.CHUYENMON, 
    RTRIM(GV.MAKHOA) AS MAKHOA, K.TENKHOA,
    -- Directly check database_principals without JOIN to server_principals
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM sys.database_principals DP
            WHERE DP.name = RTRIM(GV.MAGV) AND DP.type = 'S'
        ) 
        THEN 1 
        ELSE 0 
    END AS HasLogin,
    CASE
        WHEN EXISTS (
            SELECT 1 
            FROM sys.database_principals DP
            JOIN sys.database_role_members RM ON RM.member_principal_id = DP.principal_id
            JOIN sys.database_principals RP ON RP.principal_id = RM.role_principal_id
            WHERE DP.name = RTRIM(GV.MAGV) AND DP.type = 'S' AND RP.name = 'pgv_role'
        ) THEN 'pgv_role'
        WHEN EXISTS (
            SELECT 1 
            FROM sys.database_principals DP
            JOIN sys.database_role_members RM ON RM.member_principal_id = DP.principal_id
            JOIN sys.database_principals RP ON RP.principal_id = RM.role_principal_id
            WHERE DP.name = RTRIM(GV.MAGV) AND DP.type = 'S' AND RP.name = 'khoa_role'
        ) THEN 'khoa_role'
        ELSE NULL
    END AS RoleName
FROM GIANGVIEN GV
JOIN KHOA K ON GV.MAKHOA = K.MAKHOA;
GO

-- =============================================
-- Description: Lấy danh sách giảng viên và trạng thái login
-- Parameters:  @MAKHOA - Mã khoa (không bắt buộc)
-- =============================================
CREATE OR ALTER PROCEDURE dbo.sp_Get_GiangVien_LoginStatus
    @MAKHOA NCHAR(10) = NULL
WITH EXECUTE AS '$(MSSQL_SUPERADMIN_USER)'
AS
BEGIN
    SET NOCOUNT ON;

    -- Use the view directly to improve consistency
    SELECT * FROM V_GIANGVIEN_WITH_LOGIN
    WHERE (@MAKHOA IS NULL OR MAKHOA = @MAKHOA)
    ORDER BY TEN, HO;
END;
GO

-- Legacy version preserved with comment
CREATE OR ALTER PROCEDURE dbo.sp_Get_GiangVien_LoginStatus_Legacy
    @MAKHOA NCHAR(10) = NULL
WITH EXECUTE AS '$(MSSQL_SUPERADMIN_USER)'
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        RTRIM(GV.MAGV) AS MAGV, GV.HO, GV.TEN, GV.HOCVI, GV.HOCHAM, GV.CHUYENMON, 
        RTRIM(GV.MAKHOA) AS MAKHOA, K.TENKHOA,
        -- Use same database_principals check as the view
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM sys.database_principals DP
                WHERE DP.name = RTRIM(GV.MAGV) AND DP.type = 'S'
            ) 
            THEN 1 
            ELSE 0 
        END AS HasLogin,
        CASE
            WHEN EXISTS (
                SELECT 1 
                FROM sys.database_principals DP
                JOIN sys.database_role_members RM ON RM.member_principal_id = DP.principal_id
                JOIN sys.database_principals RP ON RP.principal_id = RM.role_principal_id
                WHERE DP.name = RTRIM(GV.MAGV) AND DP.type = 'S' AND RP.name = 'pgv_role'
            ) THEN 'pgv_role'
            WHEN EXISTS (
                SELECT 1 
                FROM sys.database_principals DP
                JOIN sys.database_role_members RM ON RM.member_principal_id = DP.principal_id
                JOIN sys.database_principals RP ON RP.principal_id = RM.role_principal_id
                WHERE DP.name = RTRIM(GV.MAGV) AND DP.type = 'S' AND RP.name = 'khoa_role'
            ) THEN 'khoa_role'
            ELSE NULL
        END AS RoleName
    FROM GIANGVIEN GV
    JOIN KHOA K ON GV.MAKHOA = K.MAKHOA
    WHERE (@MAKHOA IS NULL OR GV.MAKHOA = @MAKHOA)
    ORDER BY GV.TEN, GV.HO;
END;
GO

-- =============================================
-- Description: Tìm kiếm giảng viên
-- Parameters:  @SEARCH - Từ khóa tìm kiếm (tên, mã giảng viên)
--              @MAKHOA - Mã khoa (không bắt buộc)
-- =============================================
CREATE OR ALTER PROCEDURE dbo.sp_Search_GiangVien
    @SEARCH NVARCHAR(50) = NULL,
    @MAKHOA NCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT GV.*, K.TENKHOA
    FROM GIANGVIEN GV
    JOIN KHOA K ON GV.MAKHOA = K.MAKHOA
    WHERE 
        (@SEARCH IS NULL OR GV.MAGV LIKE N'%' + @SEARCH + N'%' OR 
         GV.HO LIKE N'%' + @SEARCH + N'%' OR 
         GV.TEN LIKE N'%' + @SEARCH + N'%' OR
         (GV.HO + N' ' + GV.TEN) LIKE N'%' + @SEARCH + N'%') AND
        (@MAKHOA IS NULL OR GV.MAKHOA = @MAKHOA)
    ORDER BY GV.TEN, GV.HO;
END;
GO

-- =============================================
-- Description: Tìm kiếm giảng viên với bộ lọc nâng cao
-- Parameters:  @SEARCH - Từ khóa tìm kiếm (tên, mã giảng viên)
--              @MAKHOA - Mã khoa (không bắt buộc)
--              @HOCVI - Học vị (không bắt buộc)
--              @HAS_LOGIN - Có tài khoản (1) hoặc không (0) (không bắt buộc)
-- =============================================
CREATE OR ALTER PROCEDURE dbo.sp_Search_GiangVien_Advanced
    @SEARCH NVARCHAR(50) = NULL,
    @MAKHOA NCHAR(10) = NULL,
    @HOCVI NVARCHAR(20) = NULL,
    @HAS_LOGIN BIT = NULL
WITH EXECUTE AS '$(MSSQL_SUPERADMIN_USER)'
AS
BEGIN
    SET NOCOUNT ON;

    SELECT V.*
    FROM V_GIANGVIEN_WITH_LOGIN V
    WHERE 
        (@SEARCH IS NULL OR V.MAGV LIKE N'%' + @SEARCH + N'%' OR 
         V.HO LIKE N'%' + @SEARCH + N'%' OR 
         V.TEN LIKE N'%' + @SEARCH + N'%' OR
         (V.HO + N' ' + V.TEN) LIKE N'%' + @SEARCH + N'%') AND
        (@MAKHOA IS NULL OR V.MAKHOA = @MAKHOA) AND
        (@HOCVI IS NULL OR V.HOCVI = @HOCVI) AND
        (@HAS_LOGIN IS NULL OR V.HasLogin = @HAS_LOGIN)
    ORDER BY V.TEN, V.HO;
END;
GO

-- =============================================
-- Description: Thêm giảng viên mới
-- =============================================
CREATE OR ALTER PROCEDURE dbo.sp_GiangVien_Create
    @MAGV NCHAR(10),
    @HO NVARCHAR(50),
    @TEN NVARCHAR(10),
    @MAKHOA NCHAR(10),
    @HOCVI NVARCHAR(20) = NULL,
    @HOCHAM NVARCHAR(20) = NULL,
    @CHUYENMON NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Kiểm tra MAGV đã tồn tại chưa
    IF EXISTS (SELECT 1 FROM GIANGVIEN WHERE MAGV = @MAGV)
    BEGIN
        RAISERROR(N'Mã giảng viên đã tồn tại', 16, 1);
        RETURN;
    END
    
    -- Kiểm tra MAKHOA có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM KHOA WHERE MAKHOA = @MAKHOA)
    BEGIN
        RAISERROR(N'Mã khoa không tồn tại', 16, 1);
        RETURN;
    END
    
    -- Thêm giảng viên mới
    INSERT INTO GIANGVIEN (MAGV, HO, TEN, MAKHOA, HOCVI, HOCHAM, CHUYENMON)
    VALUES (@MAGV, @HO, @TEN, @MAKHOA, @HOCVI, @HOCHAM, @CHUYENMON);
    
    -- Trả về thông tin giảng viên vừa thêm
    SELECT GV.*, K.TENKHOA
    FROM GIANGVIEN GV
    JOIN KHOA K ON GV.MAKHOA = K.MAKHOA
    WHERE GV.MAGV = @MAGV;
END;
GO

-- =============================================
-- Description: Cập nhật thông tin giảng viên
-- =============================================
CREATE OR ALTER PROCEDURE dbo.sp_GiangVien_Update
    @MAGV NCHAR(10),
    @HO NVARCHAR(50),
    @TEN NVARCHAR(10),
    @MAKHOA NCHAR(10),
    @HOCVI NVARCHAR(20) = NULL,
    @HOCHAM NVARCHAR(20) = NULL,
    @CHUYENMON NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Kiểm tra MAGV có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM GIANGVIEN WHERE MAGV = @MAGV)
    BEGIN
        RAISERROR(N'Mã giảng viên không tồn tại', 16, 1);
        RETURN;
    END
    
    -- Kiểm tra MAKHOA có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM KHOA WHERE MAKHOA = @MAKHOA)
    BEGIN
        RAISERROR(N'Mã khoa không tồn tại', 16, 1);
        RETURN;
    END
    
    -- Cập nhật thông tin giảng viên
    UPDATE GIANGVIEN
    SET HO = @HO,
        TEN = @TEN,
        MAKHOA = @MAKHOA,
        HOCVI = @HOCVI,
        HOCHAM = @HOCHAM,
        CHUYENMON = @CHUYENMON
    WHERE MAGV = @MAGV;
    
    -- Trả về thông tin giảng viên sau khi cập nhật
    SELECT GV.*, K.TENKHOA
    FROM GIANGVIEN GV
    JOIN KHOA K ON GV.MAKHOA = K.MAKHOA
    WHERE GV.MAGV = @MAGV;
END;
GO

-- =============================================
-- Description: Xóa giảng viên
-- =============================================
CREATE OR ALTER PROCEDURE dbo.sp_GiangVien_Delete
    @MAGV NCHAR(10)
WITH EXECUTE AS '$(MSSQL_SUPERADMIN_USER)'
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Kiểm tra MAGV có tồn tại không
        IF NOT EXISTS (SELECT 1 FROM GIANGVIEN WHERE MAGV = @MAGV)
        BEGIN
            RAISERROR(N'Mã giảng viên không tồn tại', 16, 1);
            ROLLBACK;
            RETURN;
        END
        
        -- Kiểm tra giảng viên có đang được sử dụng trong LOPTINCHI không
        IF EXISTS (SELECT 1 FROM LOPTINCHI WHERE MAGV = @MAGV)
        BEGIN
            RAISERROR(N'Không thể xóa giảng viên đang có lớp tín chỉ', 16, 1);
            ROLLBACK;
            RETURN;
        END
        
        -- Kiểm tra và xóa user/login nếu có
        IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = RTRIM(@MAGV))
        BEGIN
            -- Gọi procedure xóa tài khoản
            EXEC sp_Delete_GiangVien_Login @MAGV;
        END
        
        -- Xóa giảng viên
        DELETE FROM GIANGVIEN WHERE MAGV = @MAGV;
        
        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO

-- =============================================
-- Description: Xóa tài khoản giảng viên
-- Parameters:  @MAGV - Mã giảng viên
-- =============================================
CREATE OR ALTER PROCEDURE dbo.sp_Delete_GiangVien_Login
    @MAGV NCHAR(10)
WITH EXECUTE AS '$(MSSQL_SUPERADMIN_USER)'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @MAGV_CLEAN NVARCHAR(10) = RTRIM(@MAGV);
    
    -- Kiểm tra xem giảng viên có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM GIANGVIEN WHERE RTRIM(MAGV) = @MAGV_CLEAN)
    BEGIN
        RAISERROR(N'Mã giảng viên không tồn tại', 16, 1);
        RETURN;
    END
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Gọi procedure xóa tài khoản và login
        EXEC dbo.sp_Xoa_Login_User_GiangVien @MAGV = @MAGV_CLEAN;
        
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
        
        -- Kiểm tra lỗi "module not found" (mã lỗi 17750)
        IF ERROR_NUMBER() = 17750
        BEGIN
            -- Log the error but don't fail
            PRINT 'Module not found error occurred but user was successfully dropped';
            
            -- Nếu transaction đã rollback, cần commit để đảm bảo user đã được drop
            IF @@TRANCOUNT > 0
                COMMIT;
                
            RETURN;
        END
        ELSE
        BEGIN
            -- For other errors, propagate them
            DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
            DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
            DECLARE @ErrorState INT = ERROR_STATE();
            
            RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        END
    END CATCH
END;
GO

-- =============================================
-- Description: Tạo Login và User cho giảng viên
-- Parameters:  @LoginName - Tên đăng nhập
--              @Password - Mật khẩu
--              @MAGV - Mã giảng viên (sẽ là tên user trong DB)
-- =============================================
CREATE OR ALTER PROCEDURE dbo.sp_Tao_Login_User_GiangVien
    @LoginName NVARCHAR(128),
    @Password NVARCHAR(128),
    @MAGV NCHAR(10)
WITH EXECUTE AS '$(MSSQL_SUPERADMIN_USER)'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MAGV_CLEAN NVARCHAR(10) = RTRIM(@MAGV);
    DECLARE @UserSID VARBINARY(85)
    DECLARE @LoginSID VARBINARY(85)

    -- 1. Kiểm tra DB user đã tồn tại?
    SELECT @UserSID = sid FROM sys.database_principals WHERE name = @MAGV_CLEAN
    IF @UserSID IS NOT NULL
    BEGIN
        RAISERROR(N'Người dùng [%s] đã có tài khoản đăng nhập.', 16, 1, @MAGV_CLEAN)
        RETURN
    END

    -- 2. Kiểm tra login đã tồn tại?
    SELECT @LoginSID = sid FROM sys.server_principals WHERE name = @LoginName
    IF @LoginSID IS NOT NULL
    BEGIN
        RAISERROR(N'Tên tài khoản đăng nhập [%s] đã được người khác sử dụng.', 16, 1, @LoginName)
        RETURN
    END

    -- 3. Tạo login
    DECLARE @sql NVARCHAR(MAX) = N'CREATE LOGIN ' + QUOTENAME(@LoginName) 
                              + N' WITH PASSWORD = ' + QUOTENAME(@Password, '''') 
                              + N', CHECK_POLICY = OFF';
    EXEC (@sql);

    -- 4. Tạo DB user gán với login
    SET @sql = N'CREATE USER ' + QUOTENAME(@MAGV_CLEAN) 
             + N' FOR LOGIN ' + QUOTENAME(@LoginName);
    EXEC (@sql);
END
GO

-- =============================================
-- Description: Xóa Login và User của giảng viên
-- Parameters:  @MAGV - Mã giảng viên
-- =============================================
CREATE OR ALTER PROCEDURE dbo.sp_Xoa_Login_User_GiangVien
    @MAGV NCHAR(10)
WITH EXECUTE AS '$(MSSQL_SUPERADMIN_USER)'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MAGV_CLEAN NVARCHAR(10) = RTRIM(@MAGV);
    DECLARE @UserSID VARBINARY(85)
    SELECT @UserSID = sid FROM sys.database_principals WHERE name = @MAGV_CLEAN

    IF @UserSID IS NULL
    BEGIN
        RAISERROR(N'Không tồn tại DB user [%s] để xóa.', 16, 1, @MAGV_CLEAN)
        RETURN
    END

    -- Xóa DB user
    DECLARE @sql NVARCHAR(200) = N'DROP USER ' + QUOTENAME(@MAGV_CLEAN);
    EXEC (@sql);

    -- Tìm login tương ứng theo SID
    DECLARE @LoginName SYSNAME
    SELECT @LoginName = name FROM sys.server_principals WHERE sid = @UserSID

    IF @LoginName IS NOT NULL
    BEGIN
        SET @sql = N'DROP LOGIN ' + QUOTENAME(@LoginName);
        EXEC (@sql);
    END
END
GO

-- =============================================
-- Description: Cập nhật quyền của giảng viên
-- Parameters:  @MAGV - Mã giảng viên
--              @ROLE - Nhóm quyền mới (pgv_role/khoa_role)
-- =============================================
CREATE OR ALTER PROCEDURE dbo.sp_Update_GiangVien_Role
    @MAGV NCHAR(10),
    @ROLE SYSNAME
WITH EXECUTE AS '$(MSSQL_SUPERADMIN_USER)'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @MAGV_CLEAN NVARCHAR(10) = RTRIM(@MAGV);
    DECLARE @CURRENT_ROLE NVARCHAR(50);
    
    -- Kiểm tra giảng viên tồn tại
    IF NOT EXISTS (SELECT 1 FROM GIANGVIEN WHERE RTRIM(MAGV) = @MAGV_CLEAN)
    BEGIN
        RAISERROR(N'Mã giảng viên không tồn tại', 16, 1);
        RETURN;
    END
    
    -- Kiểm tra giảng viên có tài khoản không
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @MAGV_CLEAN AND type = 'S')
    BEGIN
        RAISERROR(N'Giảng viên chưa có tài khoản đăng nhập', 16, 1);
        RETURN;
    END
    
    -- Kiểm tra role hợp lệ
    IF @ROLE NOT IN (N'pgv_role', N'khoa_role')
    BEGIN
        RAISERROR(N'ROLE phải là pgv_role hoặc khoa_role', 16, 1);
        RETURN;
    END
    
    -- Lấy role hiện tại
    SELECT @CURRENT_ROLE = 
        CASE
            WHEN EXISTS (
                SELECT 1 
                FROM sys.database_principals DP
                JOIN sys.database_role_members RM ON RM.member_principal_id = DP.principal_id
                JOIN sys.database_principals RP ON RP.principal_id = RM.role_principal_id
                WHERE DP.name = @MAGV_CLEAN AND DP.type = 'S' AND RP.name = 'pgv_role'
            ) THEN 'pgv_role'
            WHEN EXISTS (
                SELECT 1 
                FROM sys.database_principals DP
                JOIN sys.database_role_members RM ON RM.member_principal_id = DP.principal_id
                JOIN sys.database_principals RP ON RP.principal_id = RM.role_principal_id
                WHERE DP.name = @MAGV_CLEAN AND DP.type = 'S' AND RP.name = 'khoa_role'
            ) THEN 'khoa_role'
            ELSE NULL
        END;
    
    -- Nếu role không thay đổi, không cần cập nhật
    IF @CURRENT_ROLE = @ROLE
    BEGIN
        SELECT * FROM V_GIANGVIEN_WITH_LOGIN
        WHERE MAGV = @MAGV_CLEAN;
        RETURN;
    END
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Xóa role cũ
        IF @CURRENT_ROLE IS NOT NULL
        BEGIN
            DECLARE @sql NVARCHAR(200) = N'ALTER ROLE ' + QUOTENAME(@CURRENT_ROLE) + 
                                       N' DROP MEMBER ' + QUOTENAME(@MAGV_CLEAN);
            EXEC (@sql);
        END
        
        -- Thêm role mới
        SET @sql = N'ALTER ROLE ' + QUOTENAME(@ROLE) + 
                 N' ADD MEMBER ' + QUOTENAME(@MAGV_CLEAN);
        EXEC (@sql);
        
        COMMIT;
        
        -- Trả về thông tin giảng viên cùng trạng thái login
        SELECT * FROM V_GIANGVIEN_WITH_LOGIN
        WHERE MAGV = @MAGV_CLEAN;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO

-- =============================================
-- Description: Cập nhật mật khẩu tài khoản giảng viên
-- Parameters:  @MAGV - Mã giảng viên
--              @NEW_PASSWORD - Mật khẩu mới
-- =============================================
CREATE OR ALTER PROCEDURE dbo.sp_Update_GiangVien_Password
    @MAGV NCHAR(10),
    @NEW_PASSWORD NVARCHAR(128)
WITH EXECUTE AS '$(MSSQL_SUPERADMIN_USER)'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @MAGV_CLEAN NVARCHAR(10) = RTRIM(@MAGV);
    DECLARE @LOGINNAME NVARCHAR(128);
    
    -- Kiểm tra giảng viên tồn tại
    IF NOT EXISTS (SELECT 1 FROM GIANGVIEN WHERE RTRIM(MAGV) = @MAGV_CLEAN)
    BEGIN
        RAISERROR(N'Mã giảng viên không tồn tại', 16, 1);
        RETURN;
    END
    
    -- Kiểm tra giảng viên có tài khoản không
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @MAGV_CLEAN AND type = 'S')
    BEGIN
        RAISERROR(N'Giảng viên chưa có tài khoản đăng nhập', 16, 1);
        RETURN;
    END
    
    -- Lấy login name từ user
    SELECT @LOGINNAME = SP.name
    FROM sys.database_principals DP
    JOIN sys.server_principals SP ON DP.sid = SP.sid
    WHERE DP.name = @MAGV_CLEAN AND DP.type = 'S';
    
    IF @LOGINNAME IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy login tương ứng', 16, 1);
        RETURN;
    END
    
    -- Cập nhật mật khẩu
    DECLARE @sql NVARCHAR(MAX) = N'ALTER LOGIN ' + QUOTENAME(@LOGINNAME) + 
                             N' WITH PASSWORD = ' + QUOTENAME(@NEW_PASSWORD, '''') + 
                             N', CHECK_POLICY = OFF';
    BEGIN TRY
        EXEC (@sql);
        
        -- Trả về thông tin giảng viên
        SELECT * FROM V_GIANGVIEN_WITH_LOGIN
        WHERE MAGV = @MAGV_CLEAN;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

-- =============================================
-- Description: Vô hiệu hóa tài khoản giảng viên (không xóa)
-- Parameters:  @MAGV - Mã giảng viên
--              @IS_DISABLED - 1: vô hiệu hóa, 0: kích hoạt
-- =============================================
CREATE OR ALTER PROCEDURE dbo.sp_Toggle_GiangVien_Login
    @MAGV NCHAR(10),
    @IS_DISABLED BIT
WITH EXECUTE AS '$(MSSQL_SUPERADMIN_USER)'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @MAGV_CLEAN NVARCHAR(10) = RTRIM(@MAGV);
    DECLARE @LOGINNAME NVARCHAR(128);
    
    -- Kiểm tra giảng viên tồn tại
    IF NOT EXISTS (SELECT 1 FROM GIANGVIEN WHERE RTRIM(MAGV) = @MAGV_CLEAN)
    BEGIN
        RAISERROR(N'Mã giảng viên không tồn tại', 16, 1);
        RETURN;
    END
    
    -- Kiểm tra giảng viên có tài khoản không
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @MAGV_CLEAN AND type = 'S')
    BEGIN
        RAISERROR(N'Giảng viên chưa có tài khoản đăng nhập', 16, 1);
        RETURN;
    END
    
    -- Lấy login name từ user
    SELECT @LOGINNAME = SP.name
    FROM sys.database_principals DP
    JOIN sys.server_principals SP ON DP.sid = SP.sid
    WHERE DP.name = @MAGV_CLEAN AND DP.type = 'S';
    
    IF @LOGINNAME IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy login tương ứng', 16, 1);
        RETURN;
    END
    
    -- Thay đổi trạng thái tài khoản
    DECLARE @sql NVARCHAR(MAX);
    IF @IS_DISABLED = 1
        SET @sql = N'ALTER LOGIN ' + QUOTENAME(@LOGINNAME) + N' DISABLE';
    ELSE
        SET @sql = N'ALTER LOGIN ' + QUOTENAME(@LOGINNAME) + N' ENABLE';
    
    BEGIN TRY
        EXEC (@sql);
        
        -- Lấy trạng thái hiện tại của login
        DECLARE @CurrentStatus BIT;
        SELECT @CurrentStatus = CONVERT(BIT, is_disabled)
        FROM sys.server_principals
        WHERE name = @LOGINNAME;
        
        -- Trả về thông tin giảng viên và trạng thái hiện tại
        SELECT 
            GV.*, 
            @CurrentStatus AS IsDisabled
        FROM V_GIANGVIEN_WITH_LOGIN GV
        WHERE GV.MAGV = @MAGV_CLEAN;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

-- =============================================
-- Description: Tạo tài khoản cho giảng viên đã tồn tại
-- Parameters:  @MAGV - Mã giảng viên 
--              @LOGINNAME - Tên đăng nhập SQL Server
--              @PASSWORD - Mật khẩu
--              @ROLE - Nhóm quyền (pgv_role/khoa_role)
-- =============================================
CREATE OR ALTER PROCEDURE dbo.sp_Create_GiangVien_Login
    @LOGINNAME SYSNAME,
    @PASSWORD NVARCHAR(128),
    @MAGV NCHAR(10),
    @ROLE SYSNAME
WITH EXECUTE AS '$(MSSQL_SUPERADMIN_USER)'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @MAGV_CLEAN NVARCHAR(10) = RTRIM(@MAGV);
    
    -- Kiểm tra giảng viên tồn tại
    IF NOT EXISTS (SELECT 1 FROM GIANGVIEN WHERE RTRIM(MAGV) = @MAGV_CLEAN)
    BEGIN
        RAISERROR(N'Mã giảng viên không tồn tại', 16, 1);
        RETURN;
    END
    
    -- Kiểm tra role hợp lệ
    IF @ROLE NOT IN (N'pgv_role', N'khoa_role')
    BEGIN
        RAISERROR(N'ROLE phải là pgv_role hoặc khoa_role', 16, 1);
        RETURN;
    END
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Tạo login và user bằng procedure mới
        EXEC dbo.sp_Tao_Login_User_GiangVien
            @LoginName = @LOGINNAME,
            @Password = @PASSWORD,
            @MAGV = @MAGV_CLEAN;

        -- Thêm USER vào ROLE
        DECLARE @sql NVARCHAR(200) = N'ALTER ROLE ' + QUOTENAME(@ROLE) 
                + N' ADD MEMBER ' + QUOTENAME(@MAGV_CLEAN);
        EXEC (@sql);
        
        COMMIT;
        
        -- Trả về thông tin giảng viên cùng trạng thái login
        SELECT * FROM V_GIANGVIEN_WITH_LOGIN
        WHERE MAGV = @MAGV_CLEAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

-- Grant execute permissions
GRANT EXECUTE ON dbo.sp_Get_GiangVien_LoginStatus TO pgv_role;
GRANT EXECUTE ON dbo.sp_Get_GiangVien_LoginStatus TO khoa_role;
GRANT EXECUTE ON dbo.sp_Check_GiangVien_HasLogin TO pgv_role;
GRANT EXECUTE ON dbo.sp_Delete_GiangVien_Login TO pgv_role;
GRANT EXECUTE ON dbo.sp_Them_GiangVien TO pgv_role;
GRANT EXECUTE ON dbo.sp_GiangVien_Create TO pgv_role;
GRANT EXECUTE ON dbo.sp_GiangVien_Update TO pgv_role;
GRANT EXECUTE ON dbo.sp_GiangVien_Delete TO pgv_role;
GRANT EXECUTE ON dbo.sp_Create_GiangVien_Login TO pgv_role;
GRANT EXECUTE ON dbo.sp_Update_GiangVien_Role TO pgv_role;
GRANT EXECUTE ON dbo.sp_Update_GiangVien_Password TO pgv_role;
GRANT EXECUTE ON dbo.sp_Toggle_GiangVien_Login TO pgv_role;
GRANT EXECUTE ON dbo.sp_Search_GiangVien TO pgv_role, khoa_role;
GRANT EXECUTE ON dbo.sp_Search_GiangVien_Advanced TO pgv_role, khoa_role;
GO 