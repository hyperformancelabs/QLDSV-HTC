--- START OF FILE Bai tap 1 - Tao CSDL QLVT.docx (Converted - 2025-05-21 22:18) ---

# Bài 1. Tạo cơ sở dữ liệu QLVT gồm các tables sau:

## a. Table Nhanvien

| Field Name | Type        | Constraint                                                              |
| :--------- | :---------- | :---------------------------------------------------------------------- |
| MANV       | int         | Primary key                                                             |
| HO         | nvarchar(40)|                                                                         |
| TEN        | nvarchar(10)|                                                                         |
| PHAI       | nvarchar(3) | Default: ‘Nam’; CHECK (PHAI IN (‘Nam’, ‘Nữ’))                           |
| DIACHI     | nvarchar(50)| Not Null, Default: ‘ ‘                                                  |
| NGAYSINH   | Date        |                                                                         |
| LUONG      | Money       | CHECK (LUONG >= 5000000 AND LUONG <= 50000000), Default: 5000000       |
| GHICHU     | nText       |                                                                         |

## b. Table Kho:

| Field Name | Type        | Constraint                 |
| :--------- | :---------- | :------------------------- |
| MAKHO      | nChar(2)    | Primary Key                |
| TENKHO     | nvarchar(30)| Unique, Not Null           |
| DIACHI     | nvarchar(70)| Not Null                   |

## c. Table Vattu:

| Field Name | Type        | Constraint                 |
| :--------- | :---------- | :------------------------- |
| MAVT       | nChar(4)    | Primary Key                |
| TENVT      | nvarchar(30)| Unique, Not Null           |
| DVT        | nvarchar(15)| Default: ‘cái’             |

## d. Table Phatsinh:

| Field Name | Type         | Constraint                                                                 |
| :--------- | :----------- | :------------------------------------------------------------------------- |
| SOPHIEU    | nChar(8)     | Primary Key                                                                |
| NGAY       | DateTime     | Default: GETDATE() (ngày hiện hành của hệ thống)                             |
| LOAI       | Char(1)      | CHECK (LOAI IN (‘N’, ‘X’)), Default: ‘N’                                   |
| HOTEN_KH   | nvarchar(40) | Default: “ “                                                               |
| MANV       | INT          | Foreign key (tham chiếu đến Nhanvien(MANV))                               |
| LYDO       | nvarchar(30) |                                                                            |

## e. Table CT_Phatsinh:

| Field Name | Type     | Properties/Constraint                                                    |
| :--------- | :------- | :----------------------------------------------------------------------- |
| SOPHIEU    | nChar(8) | Foreign Key (tham chiếu đến Phatsinh(SOPHIEU))                           |
| MAVT       | nChar(4) | Foreign Key (tham chiếu đến Vattu(MAVT))                                 |
| SOLUONG    | int      | CHECK (SOLUONG > 0)                                                      |
| DONGIA     | float    | CHECK (DONGIA > 0)                                                       |
| MAKHO      | nChar(2) | Foreign Key (tham chiếu đến Kho(MAKHO))                                  |
**Khóa chính**: (SOPHIEU, MAVT)

Dùng Diagram để thiết kế mối quan hệ giữa các tables trong cơ sở dữ liệu QLVT.

---

# Bài 2. Viết các stored procedure hoặc View truy vấn các thông tin sau bằng ngôn ngữ SQL:

1.  Liệt kê (MANV, HOTEN) chưa lập phiếu nhập trong năm `@nam`.
2.  Liệt kê chi tiết các mặt hàng đã xuất trong hóa đơn có mã số `@sohd`. Kết xuất:
    `Ngay MaMH TenMH Soluong Dongia Trigia`
3.  Liệt kê các phiếu nhập trong 6 tháng đầu năm của năm `@nam`.
    Kết xuất: `SoPhieu Ngay Manv HotenNV`
4.  Đếm số lượng nhân viên trong công ty.
5.  Đếm số lượng phiếu đã lập trong CSDL.
6.  Liệt kê các nhân viên có lương trong khoảng `@luongmin`, `@luongmax` trong công ty. Kết xuất:
    `MANV HOTEN NGAYSINH LUONG`
7.  Liệt kê các phiếu thuộc loại `@loai` đã lập trong khoảng thời gian `@tungay`, `@denngay`. Kết xuất:
    `PHIEU NGAYLAP THANHTIEN HOTENNV`
8.  Đếm số lượng mã vật tư trong công ty.
9.  Đếm xem vật tư có mã `@mavt` đã nhập/xuất bao nhiêu lần.
    a/ Kết xuất: `MAVT TENVT SOLUOT_NHAP_XUAT`
    b/ Kết xuất: `MAVT TENVT SOLUOT_NHAP SOLUOT_XUAT`
10. Thống kê các phiếu thuộc loại `@loai` đã lập trong năm `@nam` của từng nhân viên.
    Kết xuất: `MANV HOTEN SOLUOT_LAP_PHIEU`
11. Liệt kê doanh thu của cửa hàng theo từng tháng trong năm `@nam`. Tháng không có doanh thu vẫn in.
    Kết xuất: `Tháng Doanh thu`
12. Liệt kê số lượng tồn của vật tư có mã `@mavt`.
13. Liệt kê số lượng tồn của các vật tư trong cửa hàng.
    Kết xuất: `MAVT TENVT TongNhap TongXuat SOLUONG_TON`
    3 bước:
    *   Tạo `#TgNhap` : `MAVT TongNhap`
    *   Tạo `#TgXuat` : `MAVT TongXuat`
    *   Kết `#TgNhap`, `#TgXuat` → Kết quả

--- END OF FILE Bai tap 1 - Tao CSDL QLVT.docx (Converted - 2025-05-21 22:18) ---