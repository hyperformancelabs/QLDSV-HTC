-- Stored procedure for KHOA (faculty)
-- File: 04-khoa-procedures.sql
-- Applies to $(DB_NAME)

USE [$(DB_NAME)];
GO

/*===========================================================
  SP_KHOA_Select
  Purpose   : Trả về danh sách khoa
===========================================================*/
CREATE OR ALTER PROCEDURE dbo.SP_KHOA_Select
AS
BEGIN
    SET NOCOUNT ON;

    SELECT MAKHOA,
           TENKHOA
    FROM   dbo.KHOA WITH (NOLOCK)
    ORDER  BY TENKHOA;
END;
GO

-- Phân quyền
GRANT EXECUTE ON dbo.SP_KHOA_Select TO pgv_role, khoa_role;
GO 