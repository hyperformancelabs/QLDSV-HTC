# ĐỀ TÀI MÔN  HỆ QUẢN TRỊ CSDL

## Đề 1. QUẢN LÝ ĐIỂM SINH VIÊN THEO HỆ TÍN CHỈ

Cho cơ sở dữ liệu QLDSV\_HTC sau:

### a. Khoa :

| FieldName | Type         | Constraint       |
| --------- | ------------ | ---------------- |
| MAKHOA    | nChar(10)    | Primary Key      |
| TENKHOA   | nVarchar(50) | Unique, not NULL |

### b. Lớp :

| FieldName | Type         | Constraint       |
| --------- | ------------ | ---------------- |
| MALOP     | nChar(10)    | Primary Key      |
| TENLOP    | nVarchar(50) | Unique, not NULL |
| KHOAHOC   | nchar(9)     | not NULL         |
| MAKHOA    | nChar(10)    | FK, not NULL     |

### c. Table Sinhvien:

| FieldName | Type          | Constraint                             |
| --------- | ------------- | -------------------------------------- |
| MASV      | nChar(10)     | Primary key                            |
| HO        | nVarchar(50)  | not NULL                               |
| TEN       | nVarchar(10)  | not NULL                               |
| MALOP     | nChar(10)     | Foreign Key, not NULL                  |
| PHAI      | Bit           | Default : false (false: Nam; true: Nữ) |
| NGAYSINH  | DateTime      |                                        |
| DIACHI    | nVarchar(100) |                                        |
| DANGHIHOC | Bit           | Default : false                        |
| PASSWORD  | nVarchar(40)  | Default: 123456                        |

### d. Cấu trúc của Table Monhoc:

| FieldName  | Type         | Constraint           |
| ---------- | ------------ | -------------------- |
| MAMH       | nChar(10)    | Primary key          |
| TENMH      | nVarchar(50) | Unique Key, not NULL |
| SOTIET\_LT | int          | not NULL             |
| SOTIET\_TH | int          | not NULL             |

### e. Cấu trúc của Table GIANGVIEN:

| Field Name | Type         | Constraint   |
| ---------- | ------------ | ------------ |
| MAGV       | nChar(10)    | Primary Key  |
| HO         | nvarchar(50) | not NULL     |
| TEN        | nvarchar(10) | not NULL     |
| HOCVI      | nvarchar(20) |              |
| HOCHAM     | nvarchar(20) |              |
| CHUYENMON  | nvarchar(50) |              |
| MAKHOA     | nCHAR(10)    | FK, not NULL |

### f. Cấu trúc của Table LOPTINCHI:

| FieldName    | Type                          | Constraint            |
| ------------ | ----------------------------- | --------------------- |
| MALTC        | int                           | Primary Key (tự động) |
| NIENKHOA     | nChar(9)                      | not NULL              |
| HOCKY        | int                           | not NULL, 1<=hocky<=3 |
| MAMH         | nChar(10)                     | Foreign Key, not NULL |
| NHOM         | int                           | not NULL , >=1        |
| MAGV         | nChar(10)                     | Foreign Key, not NULL |
| MAKHOA       | nChar(10)                     | Foreign Key, not NULL |
| SOSVTOITHIEU | SmallInt                      | not NULL, >0          |
| HUYLOP       | bit                           | Default : false       |
| Unique key   | NIENKHOA+ HOCKY + MAMH + NHOM |                       |

MAKHOA: lớp tín chỉ do khoa nào quản lý

### g. Cấu trúc của Table DANGKY:

| FieldName   | Type        | Constraint                         |
| ----------- | ----------- | ---------------------------------- |
| MALTC       | int         | Foreign Key, not NULL              |
| MASV        | nChar(10)   | Foreign Key, not NULL              |
| DIEM\_CC    | int         | Điểm từ 0 đến 10                   |
| DIEM\_GK    | float       | Điểm từ 0 đến 10, làm tròn đến 0.5 |
| DIEM\_CK    | float       | Điểm từ 0 đến 10, làm tròn đến 0.5 |
| HUYDANGKY   | bit         | Default : false                    |
| Primary key | MALTC+ MASV |                                    |

---

## Yêu cầu:

Viết chương trình thực hiện các công việc sau trên từng khoa:

### 1. Đăng nhập:

#### GIẢNG VIÊN  |  SINH VIÊN

Login:

Password:

Trước khi sinh viên/giảng viên sử dụng chương trình thì phải đăng ký trước. Đối với sinh viên thì tất cả sinh viên dùng chung login sv để kết nối, lúc này label Login chuyển thành Mã SV.

### 2. Nhập liệu: gồm các công việc sau

* **Nhập danh mục lớp:** Form có các chức năng sau Thêm, Xóa, Ghi, Phục hồi, Thoát; Chức năng này do tài khoản thuộc nhóm PGV nhập. Trên từng khoa ta chỉ thấy được danh sách lớp thuộc khoa đó.
* **Nhập danh sách sinh viên:** dưới dạng SubForm 2 cấp. Yêu cầu: giống như lớp
* **Nhập môn học:** trên form Nhập môn học có các nút lệnh: Thêm, Xóa, Ghi, Phục hồi, Thoát. Chức năng này do tài khoản thuộc nhóm PGV nhập
* **Mở Lớp tín chỉ:** có các chức năng Thêm, Xóa, Ghi, Phục hồi thông tin của lớp tín chỉ. Chức năng này do tài khoản thuộc nhóm PGV nhập
* **Đăng ký lớp tín chỉ:** user nhập vào mã sinh viên của mình, chương trình tự động in ra các thông tin của sinh viên (họ, tên, mã lớp). Kế tiếp, user nhập vào Niên khóa, Học kỳ, chương trình sẽ tự động lọc ra các lớp tín chỉ đã mở trong niên khóa, học kỳ đó để sinh viên đăng ký (chưa hủy). Dữ liệu in ra gồm: MAMH, TENMH, nhóm, Hoten GV giảng, số sv đã đăng ký; Chức năng này do tài khoản thuộc nhóm PGV thực hiện.
* **Nhập điểm:** Điểm thuộc khoa nào thì khoa đó nhập hoặc PGV nhập. User nhập vào Niên khóa, Học kỳ, môn học, nhóm; click nút lệnh Bắt đầu thì chương trình tự động lọc ra các sinh viên có đăng ký trên lớp tín chỉ đó theo dạng sau, sau đó user chỉ nhập điểm vào.

  Điểm hết môn = Điểm CC \* 0.1 + Điểm GK \* 0.3 + ĐCK \* 0.6

  | Mã SV       | Họ tên SV  | Điểm chuyên cần | Điểm giữa kỳ | Điểm cuối kỳ | Điểm hết môn (read only)  |
  | ----------- | ---------- | --------------- | ------------ | ------------ | ------------------------- |
  | (read only) | (read only |                 |              |              | (tự động tính, read only) |

Sau khi nhập điểm thi xong, **click nút lệnh ‘Ghi điểm’** **thì mới ghi hết điểm về CSDL**.

### 3. Phân quyền:

Chương trình có các nhóm: PGV (phòng giáo vụ), KHOA, SV

* Nếu login thuộc nhóm PGV thì login đó có toàn quyền. Login nhóm này được tạo tài khoản cho nhóm PGV, Khoa.
* Nếu login thuộc nhóm Khoa thì ta không cho nhập Khoa, Lớp, Giảng viên, Sinh viên, mở Lớp tín chỉ; Login này được tạo tài khoản cho nhóm Khoa.
* Nhóm SV: được đăng ký lớp tín chỉ, xem Phiếu điểm của chính mình. Tất cả sinh viên đều dùng chung 1 login đăng nhập.

Chương trình cho phép ta tạo các login, password và cho login này làm việc với quyền hạn tương ứng. Căn cứ vào quyền này khi user login vào hệ thống, ta sẽ biết người đó được quyền làm việc với chức năng tương ứng.

### 4. In ấn : gồm các chức năng sau:

* **Danh sách lớp tín chỉ:** user nhập vào Niên khóa, học kỳ, chương trình in ra các lớp tín chỉ đã mở (chưa hủy) trong Niên khóa, học kỳ thuộc khoa mà user đang chọn. Mẫu in (in theo thứ tự tên môn học, nhóm):

  KHOA XXXXXXXXXXXX

  Niên khóa: ####-####   Học kỳ: #

  | STT | Tên môn học | Nhóm | Họ tên GV giảng | Số SV tối thiểu | Số SV đã đăng ký |
  | --- | ----------- | ---- | --------------- | --------------- | ---------------- |

  Số lượng lớp đã mở: ###

* **Danh sách sinh viên đăng ký lớp tín chỉ:** user nhập vào Niên khóa, học kỳ, môn học, nhóm, chương trình in ra danh sách theo thứ tự tăng dần tên+họ với mẫu sau:

  DANH SÁCH SINH VIÊN ĐĂNG KÝ LỚP TÍN CHỈ

  KHOA XXXXXXXXXXXX

  Niên khóa: ####-####   Học kỳ: #

  Môn học: XXXXXXXXXXX – Nhóm: #

  | STT | Mã SV | Họ | Tên | Phái | Mã lớp |
  | --- | ----- | -- | --- | ---- | ------ |

  Số sinh viên đã đăng ký: ###

* **Bảng điểm môn học của 1 lớp tín chỉ:** user nhập vào Niên khóa, học kỳ, môn học, nhóm, chương trình in ra bảng điểm theo thứ tự tăng dần tên+họ với mẫu sau:

  BẢNG ĐIỂM HẾT MÔN

  KHOA XXXXXXXXXXXX

  Niên khóa: ####-####   Học kỳ: #

  Môn học: XXXXXXXXXXX – Nhóm: #

  | STT | Mã SV | Họ | Tên | Điểm chuyên cần | Điểm giữa kỳ | Điểm cuối kỳ | Điểm hết môn |
  | --- | ----- | -- | --- | --------------- | ------------ | ------------ | ------------ |

  Số sinh viên: ###

* **Phiếu Điểm:** để in phiếu điểm cho một sinh viên dựa vào mã sinh viên do ta nhập hay chọn từ trong một danh sách.

  * Phiếu điểm gồm có các cột: STT, TÊN MÔN HỌC, ĐIỂM.
  * Thứ tự in điểm là theo tên môn học
  * Điểm là điểm Max của các lần thi (nếu có).

* **In danh sách đóng học phí của lớp:** User nhập vào mã lớp, niên khóa, học kỳ, chương trình sẽ in ra thông tin đóng học phí của sinh viên của niên khóa, học kỳ đó với mẫu sau (Sinh viên nào chưa đóng cũng in ra):

  DANH SÁCH SINH VIÊN ĐÓNG HỌC PHÍ

  MÃ LỚP: XXXXXXXXXXXX

  KHOA: XXXXXXXXXXXXX

  | STT | Họ và tên | Học phí | Số tiền đã đóng |
  | --- | --------- | ------- | --------------- |

  Tổng số sinh viên: ###

  Tổng số tiền đã đóng: #,###,##0 (tiền chữ)

* **Bảng điểm tổng kết:** Bảng điểm tổng kết của 1 lớp dựa vào mã lớp nhập vào. Điểm thi là điểm lớn nhất của các lần thi. (Cross-Tab)

  BẢNG ĐIỂM TỔNG KẾT CUỐI KHÓA

  LỚP: XXXXXXXXXXXXX – KHÓA HỌC:

  KHOA: XXXXXXXXXXX

  | MASV-Họ tên | Môn học 1 | Môn học 2 | Môn học 3 | Môn học 4 | Môn học n |
  | ----------- | --------- | --------- | --------- | --------- | --------- |

### 5. Quản trị:

#### a. Tạo tài khoản cho người dùng sử dụng phần mềm: theo mẫu sau

```less
+------------------------------------------------------+
|      TẠO TÀI KHOẢN ĐĂNG NHẬP CHƯƠNG TRÌNH           |
|------------------------------------------------------|
|  Họ tên nhân viên: [Châu Văn Vân ▼ ]   Mã NV: GV/N-20301      |
|  Tài khoản:          [_______________________]        |
|  Mật mã:             [_______________________]        |
|  Nhóm quyền:         [ADMIN ▼ ]                       |
|                                                      |
|  [ Tạo tài khoản ]   [ Xóa tài khoản ]   [ Thoát ]   |
+------------------------------------------------------+
```

#### b. Sao lưu & Phục hồi cơ sở dữ liệu \:có các chức năng như trong các hình dưới đây:

```
**Giao diện chính:**

* **Danh sách cơ sở dữ liệu** hiển thị bên trái, ví dụ: QL\_VATTU, QLDSV, QVANTHU...
* **Danh sách bản sao lưu** cho cơ sở dữ liệu đang chọn: thể hiện số thứ tự, diễn giải, ngày giờ sao lưu, user sao lưu.
* Nút chức năng: **Sao lưu**, **Phục hồi**, **Tham số phục hồi theo thời gian**, **Tạo device sao lưu**, **Thoát**.

**Chức năng sao lưu:**

* Lựa chọn hoặc tạo mới thiết bị sao lưu (device).
* Có tùy chọn: "Xóa tất cả các bản sao lưu cũ trong File trước khi sao lưu bản mới".

**Chức năng phục hồi:**

* Hiển thị danh sách các bản backup đã thực hiện.
* Có tùy chọn **Tham số phục hồi theo thời gian**: Nhập ngày giờ cụ thể muốn phục hồi về thời điểm đó.
* Hướng dẫn sử dụng: Thời điểm phục hồi phải sau thời điểm của bản sao lưu đã chọn trên lưới và trước thời điểm hiện tại ít nhất 1 phút.
```

* Chọn cơ sở dữ liệu cần thao tác trong danh sách bên trái;
* Nút lệnh Tạo device sao lưu: Ta phải tạo device trước thì mới được Sao lưu và Phục hồi cơ sở dữ liệu. Chương trình sẽ tự động tạo device tên theo dạng sau: DEVICE\_TENCSDL;
* Nút lệnh Sao lưu: tạo 1 bản backup cơ sở dữ liệu;
* Phục hồi: có 2 dạng

  * Phục hồi cơ sở dữ liệu về bản backup mà ta đã sao lưu
  * Nếu ta chọn thêm checkbox Tham số phục hồi theo thời gian thì sẽ phục hồi cơ sở dữ liệu về thời điểm do ta nhập vào

---

**Ghi chú:** Sinh viên tự kiểm tra các ràng buộc có thể có khi viết chương trình

**Lưu ý:** Thực hiện việc truy vấn trên SQL Server. Chỉ làm việc với các sinh viên còn đang học.

---

HẾT