# Transact-SQL Cursors

Transact-SQL cursors là kiểu con trỏ thường được dùng trong stored procedures, triggers. Nó quản lý 1 tập các records - là kết quả trả về của 1 phát biểu SQL-Select liên kết với cursor. Ta dùng cursor trong các trường hợp khi muốn xử lý từng mẫu tin trong cursor theo các cách thức khác nhau, hoặc nhận kết quả trả về từ 1 Stored Procedure.

Tiến trình khi sử dụng cursor trong Stored Procedure hoặc Trigger là:

1.  Khai báo các biến để chứa dữ liệu trả về từ cursor. Các biến này phải cùng kiểu dữ liệu với các fields trong SQL-Select.
2.  Liên kết 1 Transact-SQL cursor với 1 SELECT-SQL qua phát biểu `DECLARE CURSOR` như sau:
    ```sql
    DECLARE cursor_name CURSOR [ LOCAL | GLOBAL ]
    [ FORWARD_ONLY | SCROLL ]
    [ STATIC | KEYSET | DYNAMIC | FAST_FORWARD ] [ READ_ONLY | SCROLL_LOCKS | OPTIMISTIC ]
    [ TYPE_WARNING ]
    FOR select_statement
    [ FOR UPDATE [ OF column_name [ ,...n ] ] ]
    ```
3.  Mở cursor : `OPEN { { [ GLOBAL ] cursor_name } | cursor_variable_name }`
4.  Lấy dữ liệu từ 1 mẩu tin trong cursor và đưa dữ liệu đó vào các biến (đã khai báo trong bước 1) qua lệnh `FETCH INTO`. Transact-SQL cursors không cho phép lấy nhiều mẫu tin cùng 1 lúc.
5.  Đóng cursor

## I. Khai báo biến dữ liệu
Ta dùng lệnh `declare` để khai báo các biến nhằm để lưu trữ 1 record lấy từ cursor. Các biến này có thể được sử dụng trong các lệnh Transact SQL khác trong Stored Procedure hoặc Trigger.

## II. Liên kết 1 Transact-SQL cursor với 1 SQL-SELECT
Ta có thể làm việc trực tiếp trên cursor hoặc qua biến cursor.

1.  **Làm việc trực tiếp trên cursor**: chẳng hạn như ta tạo 1 cursor tên `Employee_Cursor` qua phát biểu `Declare` như sau:
    ```sql
    DECLARE Employee_Cursor CURSOR FOR
    SELECT LastName, FirstName FROM Northwind.dbo.Employees WHERE LastName like 'B%'

    OPEN Employee_Cursor  -- Mở cursor
    -- Lưu ý: Ví dụ này thiếu FETCH ... INTO variables và phần xử lý dữ liệu trong vòng lặp.
    FETCH NEXT FROM Employee_Cursor -- Cần INTO @Var1, @Var2
    WHILE @@FETCH_STATUS = 0 BEGIN
        -- Xử lý dữ liệu ở đây
        FETCH NEXT FROM Employee_Cursor -- Cần INTO @Var1, @Var2
    END

    CLOSE Employee_Cursor        -- Đóng cursor
    DEALLOCATE Employee_Cursor
    ```

2.  **Tạo biến cursor**: ta có 2 cách:
    1.  Tạo trước cursor, sau đó gán nó cho biến cursor:
        ```sql
        DECLARE @MyVariable CURSOR
        DECLARE MyCursor CURSOR FOR
        SELECT LastName FROM Northwind.dbo.Employees
        SET @MyVariable = MyCursor
        ```
    2.  Liên kết trực tiếp Select-SQL với biến cursor:
        ```sql
        DECLARE @MyVariable CURSOR
        SET @MyVariable = CURSOR SCROLL KEYSET FOR
        SELECT LastName FROM Northwind.dbo.Employees
        ```

Sau khi 1 cursor đã được liên kết với 1 biến cursor, biến cursor có thể được dùng thay cho tên cursor. Trong Stored procedure, ta cũng có thể khai báo output parameters có kiểu dữ liệu là cursor và được liên kết với 1 cursor.

**Cú pháp lệnh tạo cursor:**
```sql
DECLARE cursor_name CURSOR [ LOCAL | GLOBAL ]
[ FORWARD_ONLY | SCROLL ]
[ STATIC | KEYSET | DYNAMIC | FAST_FORWARD ] [ READ_ONLY | SCROLL_LOCKS ]
FOR select_statement
[ FOR UPDATE [ OF column_name [ ,...n ] ] ]
```

*   `cursor_name`: tên cursor do ta đặt.
*   `LOCAL`: phạm vi hoạt động của cursor là cục bộ trong 1 gói, SP, hoặc trigger (nơi mà cursor được tạo) . Cursor được tự động giải phóng khi ra khỏi phạm vi mà nó được tạo. Đây là giá trị mặc định.
*   `GLOBAL`: phạm vi hoạt động của cursor là toàn cục trên 1 kết nối. Tên cursor có thể được dùng trong trong các SP. Cursor được tự động giải phóng khi ra khỏi kết nối đó.
*   `FORWARD_ONLY`: ta chỉ được quyền di chuyển con trỏ mẫu tin theo 1 chiều từ mẫu tin đầu đến mẫu tin cuối. Nếu cursor là `FORWARD_ONLY` mà không có `STATIC`, `KEYSET`, or `DYNAMIC` , cursor sẽ hoạt động như là 1 `DYNAMIC` cursor. `FORWARD_ONLY` là giá trị mặc định, nhưng nếu cursor có kiểu `STATIC`, `KEYSET`, or `DYNAMIC` thì cursor sẽ là `SCROLL`.
*   `KEYSET`: các fields và thứ tự của các dòng trong cursor được cố định khi cursor được mở. Tập khóa của các dòng trong cursor được lưu trong 1 table của tempdb gọi là `keyset`.
    *   Nếu 1 dòng trong table liên kết với cursor bị xóa, lệnh fetch sẽ trả `@@FETCH_STATUS = -2`.
    *   Nếu Updates giá trị khóa ở ngoài cursor, sẽ tương đương với việc xóa dòng cũ, thêm dòng, lúc này việc fetch dòng với giá trị cũ sẽ trả về `@@FETCH_STATUS = -2`. Giá trị mới chỉ thấy được trong cursor, nếu lệnh được thực hiện với `WHERE CURRENT OF <tên cursor>`.
*   `DYNAMIC`: Nếu 1 user thay đổi dữ liệu trong base table, thì cursor kiểu này phản ánh được các dữ liệu đã thay đổi trong base table. Lưu ý rằng Fetch `ABSOLUTE` không được sử dụng trong trường hợp này.
*   `FAST_FORWARD`: Với `FORWARD_ONLY`, `READ_ONLY` cursor sẽ thực thi nhanh, tối ưu hơn. `FAST_FORWARD` không được sử dụng nếu `SCROLL` hoặc `FOR_UPDATE` được sử dụng. `FAST_FORWARD` và `FORWARD_ONLY` không được khai báo đồng thời.
*   `READ_ONLY`: không cho hiệu chỉnh các dòng trong cursor. Với `READ_ONLY`, không thể dùng `WHERE CURRENT OF <cursor>` trong lệnh `Update` hoặc `Delete`.
*   `SCROLL_LOCKS`: các dòng đã cập nhật hoặc xóa trong cursor sẽ bị khóa cho đến khi đóng cursor. `SCROLL_LOCKS` không thể dùng kèm với `FAST_FORWARD`.

`select_statement`: là 1 phát biểu Select-SQL chuẩn, lệnh select này sẽ định nghĩa 1 tập các mẫu tin cho cursor. Lưu ý: các từ khóa `COMPUTE`, `COMPUTE BY`, `FOR BROWSE`, và `INTO` không được sử dụng trong `select_statement` của 1 cursor.

`UPDATE [OF column_name [,...n]]`: cho phép ta hiệu chỉnh các fields trong cursor. Nếu `OF column_name [,...n]` được sử dụng, nghĩa là chỉ có các cột được liệt kê trong `OF` mới được hiệu chỉnh.

## @@FETCH_STATUS

Trả về 1 số nguyên cho biết trạng thái của phát biểu `FETCH`:

| Return value | Mô tả                                                 |
| :----------- | :---------------------------------------------------- |
| 0            | `FETCH` thành công.                                   |
| -1           | `FETCH` không được hoặc đã ra khỏi phạm vi tập mẫu tin. |

Lưu ý: `@@FETCH_STATUS` là biến toàn cục cho tất cả cursor trên 1 kết nối.

## FETCH
Lấy dữ liệu của dòng đưa vào các biến

```sql
FETCH
[ [ NEXT | PRIOR | FIRST | LAST
| ABSOLUTE { n | @nvar }
| RELATIVE { n | @nvar }
] FROM
]
{ { cursor_name | @cursor_variable_name } [ INTO @variable_name [ ,...n ] ] }
```

*   `NEXT`: Trả về dòng kết quả ngay sau dòng hiện tại và cho dòng kết quả trở thành dòng hiện hành. Nếu `FETCH NEXT` là lệnh đầu tiên đối với cursor, nó sẽ trả về dòng đầu tiên trong tập kết quả.
*   `PRIOR`: Trả về dòng kết quả ngay trước dòng hiện tại và cho dòng kết quả trở thành dòng hiện hành. Nếu `FETCH PRIOR` là lệnh đầu tiên đối với con trỏ, không có dòng nào được trả về.
*   `FIRST`: Trả về dòng đầu tiên của cursor và cho nó làm dòng hiện hành.
*   `LAST`: Trả về dòng cuối cùng của cursor và cho nó làm dòng hiện hành.
*   `ABSOLUTE {n | @nvar}`: Nếu `n` hoặc `@nvar` dương, trả về dòng thứ `n` tính từ đầu cursor và và cho nó làm dòng hiện hành.
*   `RELATIVE {n | @nvar}`: Nếu `n` hoặc `@nvar` dương, trả về dòng thứ `n` kể từ vị trí dòng hiện hành và cho nó làm dòng hiện hành mới. Nếu `n` or `@nvar =0` thì trả về dòng hiện hành.
*   `GLOBAL`: Specifies that `cursor_name` refers to a global cursor.
*   `cursor_name`: tên cursor cung cấp dữ liệu.
*   `INTO @variable_name[,...n]`: Đưa dữ liệu từ các cột trong cursor vào các biến. Mỗi biến trong danh sách phải tương ứng với mỗi cột trong cursor từ trái sang phải. Số lượng các biến phải khớp với số lượng cột trong cursor.

## Examples

### A. Use FETCH to store values in variables

```sql
USE pubs
GO

-- Declare the variables to store the values returned by FETCH.
DECLARE @au_lname varchar(40), @au_fname varchar(20)

DECLARE authors_cursor CURSOR FOR
SELECT au_lname, au_fname FROM authors
WHERE au_lname LIKE 'B%'
ORDER BY au_lname, au_fname

OPEN authors_cursor

-- Perform the first fetch and store the values in variables.
-- Note: The variables are in the same order as the columns
-- in the SELECT statement.
FETCH NEXT FROM authors_cursor
INTO @au_lname, @au_fname

-- Check @@FETCH_STATUS to see if there are any more rows to fetch.
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Concatenate and display the current values in the variables.
    PRINT 'Author: ' + @au_fname + ' ' + @au_lname
    -- This is executed as long as the previous fetch succeeds.
    FETCH NEXT FROM authors_cursor
    INTO @au_lname, @au_fname
END

CLOSE authors_cursor
DEALLOCATE authors_cursor
GO
```
Output:
```
Author: Abraham Bennet
Author: Reginald Blotchet-Halls
```

### C. Declare a SCROLL cursor and use the other FETCH options

This example creates a SCROLL cursor to allow full scrolling capabilities through the `LAST`, `PRIOR`, `RELATIVE`, and `ABSOLUTE` options.
```sql
USE pubs
GO

-- Execute the SELECT statement alone to show the
-- full result set that is used by the cursor.
SELECT au_lname, au_fname FROM authors
ORDER BY au_lname, au_fname

-- Declare the cursor.
DECLARE authors_cursor SCROLL CURSOR FOR
SELECT au_lname, au_fname FROM authors
ORDER BY au_lname, au_fname

OPEN authors_cursor

-- Fetch the last row in the cursor.
FETCH LAST FROM authors_cursor

-- Fetch the row immediately prior to the current row in the cursor.
FETCH PRIOR FROM authors_cursor

-- Fetch the second row in the cursor.
FETCH ABSOLUTE 2 FROM authors_cursor

-- Fetch the row that is three rows after the current row.
FETCH RELATIVE 3 FROM authors_cursor

-- Fetch the row that is two rows prior to the current row.
FETCH RELATIVE -2 FROM authors_cursor

CLOSE authors_cursor
DEALLOCATE authors_cursor
GO
```

## Ví dụ
Ta có cơ sở dữ liệu gồm có các table:

**LENHDAT**: chứa các lệnh đặt mua/bán cổ phiếu của các nhà đầu tư

| FieldName     | Type        | Description                                                                 |
|---------------|-------------|-----------------------------------------------------------------------------|
| ID            | int         | Mã số lệnh đặt                                                              |
| MACP          | char(7)     | Mã cổ phiếu                                                                |
| NGAYDAT       | datetime    |                                                                             |
| LOAIGD        | nchar(1)    | Loại giao dịch : M : lệnh mua B : lệnh bán                                  |
| LOAILENH      | nchar(10)   | Loại lệnh : LO : khớp lệnh liên tục ATO, ATC : khớp lệnh định kỳ              |
| SOLUONG       | int         | Số lượng đặt                                                               |
| GIADAT        | float       | Giá đặt                                                                     |
| TRANGTHAILENH | nvarchar(30)| Trạng thái lệnh : Chờ khớp, Khớp lệnh 1 phần, Khớp hết, Đã hủy, Chưa khớp     |

**LENHKHOP**: chứa các lệnh khớp khi thỏa qui tắc khớp lệnh

| FieldName     | Type     | Description     |
|---------------|----------|-----------------|
| IDKHOP        | int      | Mã số lệnh khớp |
| NGAYKHOP      | datetime |                 |
| SOLUONGKHOP   | int      |                 |
| GIAKHOP       | float    |                 |
| IDLENHDAT     | int      | Mã số lệnh đặt  |

Viết Stored Procedure tính số lượng cổ phiếu khớp theo thuật toán khớp lệnh liên tục khi có 1 lệnh mua hoặc bán được gởi đến bảng `LENHDAT`

```sql
CREATE PROCEDURE CursorLoaiGD
    @OutCrsr CURSOR VARYING OUTPUT,
    @macp NVARCHAR(10),
    @Ngay NVARCHAR(50),
    @LoaiGD CHAR
AS
BEGIN
    SET DATEFORMAT DMY
    IF (@LoaiGD='M')
        SET @OutCrsr = CURSOR KEYSET FOR
        SELECT NGAYDAT, SOLUONG, GIADAT FROM LENHDAT
        WHERE MACP = @macp
            AND DAY(NGAYDAT) = DAY(CONVERT(datetime, @Ngay, 103)) -- Ensure @Ngay is treated as date for DAY, MONTH, YEAR
            AND MONTH(NGAYDAT) = MONTH(CONVERT(datetime, @Ngay, 103))
            AND YEAR(NGAYDAT) = YEAR(CONVERT(datetime, @Ngay, 103))
            AND LOAIGD = @LoaiGD AND SOLUONG > 0
        ORDER BY GIADAT DESC, NGAYDAT
    ELSE
        SET @OutCrsr = CURSOR KEYSET FOR
        SELECT NGAYDAT, SOLUONG, GIADAT FROM LENHDAT
        WHERE MACP = @macp
            AND DAY(NGAYDAT) = DAY(CONVERT(datetime, @Ngay, 103))
            AND MONTH(NGAYDAT) = MONTH(CONVERT(datetime, @Ngay, 103))
            AND YEAR(NGAYDAT) = YEAR(CONVERT(datetime, @Ngay, 103))
            AND LOAIGD = @LoaiGD AND SOLUONG > 0
        ORDER BY GIADAT, NGAYDAT
    OPEN @OutCrsr
END
GO

CREATE PROC SP_KHOPLENH_LO
    @macp NVARCHAR(10),
    @Ngay NVARCHAR(50),
    @LoaiGD CHAR,
    @soluongMB INT,
    @giadatMB FLOAT
AS
BEGIN
    SET DATEFORMAT DMY
    DECLARE @CrsrVar CURSOR,
            @ngaydat DATETIME, -- Changed to DATETIME for proper comparison
            @soluong INT,
            @giadat FLOAT,
            @soluongkhop INT,
            @giakhop FLOAT

    IF (@LoaiGD = 'B') -- Lệnh gửi vào là lệnh BÁN, tìm lệnh MUA đối ứng
        EXEC CursorLoaiGD @CrsrVar OUTPUT, @macp, @Ngay, 'M'
    ELSE -- Lệnh gửi vào là lệnh MUA, tìm lệnh BÁN đối ứng
        EXEC CursorLoaiGD @CrsrVar OUTPUT, @macp, @Ngay, 'B'

    FETCH NEXT FROM @CrsrVar INTO @ngaydat, @soluong, @giadat
    -- SELECT @ngaydat , @soluong , @giadat -- For debugging

    WHILE (@@FETCH_STATUS = 0 AND @soluongMB > 0) -- Sửa @@FETCH_STATUS <> -1 thành @@FETCH_STATUS = 0
    BEGIN
        IF (@LoaiGD = 'B') -- Lệnh gửi vào là lệnh BÁN
        BEGIN
            IF (@giadatMB <= @giadat) -- Giá BÁN <= Giá MUA trong cursor
            BEGIN
                IF @soluongMB >= @soluong -- SL BÁN >= SL MUA trong cursor (khớp hết lệnh mua trong cursor)
                BEGIN
                    SET @soluongkhop = @soluong
                    SET @giakhop = @giadat -- Khớp tại giá của lệnh trong cursor (giá đặt mua)
                    SET @soluongMB = @soluongMB - @soluong
                    UPDATE dbo.LENHDAT
                    SET SOLUONG = 0, TRANGTHAILENH = N'Khớp hết' -- Cập nhật trạng thái
                    WHERE CURRENT OF @CrsrVar
                END
                ELSE -- SL BÁN < SL MUA trong cursor (khớp một phần lệnh mua trong cursor)
                BEGIN
                    SET @soluongkhop = @soluongMB
                    SET @giakhop = @giadat -- Khớp tại giá của lệnh trong cursor (giá đặt mua)
                    UPDATE dbo.LENHDAT
                    SET SOLUONG = SOLUONG - @soluongMB, TRANGTHAILENH = N'Khớp lệnh 1 phần' -- Cập nhật trạng thái
                    WHERE CURRENT OF @CrsrVar
                    SET @soluongMB = 0
                END
                -- SELECT @soluongkhop, @giakhop -- For debugging
                -- Cập nhật table LENHKHOP (logic này cần được thêm vào)
                -- INSERT INTO LENHKHOP (NGAYKHOP, SOLUONGKHOP, GIAKHOP, IDLENHDAT_MUA, IDLENHDAT_BAN) VALUES (GETDATE(), @soluongkhop, @giakhop, <ID_LENH_MUA>, <ID_LENH_BAN>)
            END
            ELSE -- Giá BÁN > Giá MUA trong cursor -> không khớp, lệnh bán chờ
            BEGIN
                 -- Với khớp lệnh liên tục, nếu lệnh bán có giá cao hơn lệnh mua đối ứng tốt nhất thì không khớp.
                 -- Nếu logic là duyệt tiếp các lệnh mua khác, thì không GOTO.
                 -- Nếu logic là lệnh bán này không khớp được với lệnh mua hiện tại thì dừng tìm kiếm cho lệnh bán này, thì GOTO.
                 -- Theo cấu trúc gốc, GOTO THOAT có nghĩa là không xét lệnh mua tiếp theo.
                GOTO THOAT 
            END
        END
        ELSE -- Lệnh gửi vào là lệnh MUA (@LoaiGD = 'M')
        BEGIN
            IF (@giadatMB >= @giadat) -- Giá MUA >= Giá BÁN trong cursor
            BEGIN
                IF @soluongMB >= @soluong -- SL MUA >= SL BÁN trong cursor (khớp hết lệnh bán trong cursor)
                BEGIN
                    SET @soluongkhop = @soluong
                    SET @giakhop = @giadat -- Khớp tại giá của lệnh trong cursor (giá đặt bán)
                    SET @soluongMB = @soluongMB - @soluong
                    UPDATE dbo.LENHDAT
                    SET SOLUONG = 0, TRANGTHAILENH = N'Khớp hết' -- Cập nhật trạng thái
                    WHERE CURRENT OF @CrsrVar
                END
                ELSE -- SL MUA < SL BÁN trong cursor (khớp một phần lệnh bán trong cursor)
                BEGIN
                    SET @soluongkhop = @soluongMB
                    SET @giakhop = @giadat -- Khớp tại giá của lệnh trong cursor (giá đặt bán)
                    UPDATE dbo.LENHDAT
                    SET SOLUONG = SOLUONG - @soluongMB, TRANGTHAILENH = N'Khớp lệnh 1 phần' -- Cập nhật trạng thái
                    WHERE CURRENT OF @CrsrVar
                    SET @soluongMB = 0
                END
                -- SELECT @soluongkhop, @giakhop -- For debugging
                -- Cập nhật table LENHKHOP (logic này cần được thêm vào)
                -- INSERT INTO LENHKHOP (NGAYKHOP, SOLUONGKHOP, GIAKHOP, IDLENHDAT_MUA, IDLENHDAT_BAN) VALUES (GETDATE(), @soluongkhop, @giakhop, <ID_LENH_MUA>, <ID_LENH_BAN>)
            END
            ELSE -- Giá MUA < Giá BÁN trong cursor -> không khớp, lệnh mua chờ
            BEGIN
                -- Tương tự trường hợp lệnh bán, nếu lệnh mua có giá thấp hơn lệnh bán đối ứng tốt nhất thì không khớp.
                GOTO THOAT
            END
        END
        
        IF @soluongMB > 0 -- Nếu lệnh gửi vào vẫn còn số lượng chưa khớp
            FETCH NEXT FROM @CrsrVar INTO @ngaydat, @soluong, @giadat
        ELSE -- Lệnh gửi vào đã khớp hết
            GOTO THOAT -- Hoặc đơn giản là `BREAK` nếu không muốn dùng GOTO
    END

THOAT:
    -- Cập nhật trạng thái cho lệnh gốc nếu nó chưa khớp hết
    IF @soluongMB > 0 
    BEGIN
        -- Logic để tìm ID của lệnh gốc (@macp, @Ngay, @LoaiGD, @soluongMB_ban_dau, @giadatMB) và cập nhật TRANGTHAILENH của nó
        -- Ví dụ: UPDATE LENHDAT SET TRANGTHAILENH = N'Chờ khớp' / N'Khớp lệnh 1 phần' WHERE ID = <ID_LENH_GOC_GUI_VAO>
        -- Điều này phức tạp hơn vì ta không có ID của lệnh gốc truyền vào SP. Cần sửa đổi SP để nhận ID lệnh gốc.
    END
    
    CLOSE @CrsrVar
    DEALLOCATE @CrsrVar
END
GO