# CHƯƠNG 2. HỆ QUẢN TRỊ SQL SERVER
## I. CÀI ĐẶT SQL SERVER: 
Xem file hướng dẫn cài đặt

## II. CÁC THUỘC TÍNH CỦA MS SQL Server Management Studio:  
Cho phép người phát triển hệ thống cấu hình lại trình quản lý theo ý mình.
Chọn lệnh: Tools / Options từ cửa sổ chính của MS SQL Server Management Studio.

**Environment/ General:**
[Hình ảnh: Tùy chọn Environment General trong SQL Server Management Studio]

**Query Execution:**
**a. General:** Thiết lập số dòng tối đa trả về trước khi server dừng thực thi truy vấn. Nếu ta muốn khống chế số dòng tối đa được xử lý trong 1 lệnh DML thì dùng lệnh SET ROWCOUNT <n>.
[Hình ảnh: Tùy chọn Query Execution General trong SQL Server Management Studio]

**b. Advanced:** Thiết lập các thông số khi thực thi query:
- SET NOCOUNT ON vào Stored Procedures để dừng thông báo về số dòng được thực thi bởi câu lệnh T-SQL. Điều này làm giảm giao dịch mạng, bởi vì máy khách sẽ không nhận được thông báo về số dòng bị tác động bởi câu lệnh T-SQL.
- Khi SET NOEXEC ON được đặt ở đầu truy vấn, truy vấn sẽ được biên dịch nhưng không được thực thi.
- Khi SET CONCAT_NULL_YIELDS_NULL được BẬT (ON), việc nối giá trị null với một chuỗi sẽ mang lại kết quả NULL. Ví dụ: SELECT 'abc' + NULL trả lại NULL. Khi SET CONCAT_NULL_YIELDS_NULL TẮT, việc ghép một giá trị null với một chuỗi sẽ tạo ra chính chuỗi đó (giá trị null được coi là một chuỗi trống). Ví dụ: SELECT 'abc' + NULL trả lại abc.
[Hình ảnh: Tùy chọn Query Execution Advanced trong SQL Server Management Studio]

**c. Designers/Table and Database Designers:**
[Hình ảnh: Tùy chọn Designers Table and Database Designers trong SQL Server Management Studio]

**d. SQL Server Object Explorer/Command:**
[Hình ảnh: Tùy chọn SQL Server Object Explorer Command trong SQL Server Management Studio]

## III. ĐĂNG KÝ VÀ HỦY ĐĂNG KÝ MỘT SERVER TRONG SQL Server Management Studio:
**1. Đăng ký Server:**
Để có thể quản lý 1 Server cục bộ (local) hay từ xa (remote) với MS SQL Server Management Studio , ta phải đăng ký server đó với MS SQL Server Management Studio. Ta chọn lệnh View / Registered Server:
[Hình ảnh: Cửa sổ Registered Servers trong SQL Server Management Studio]

Để đăng ký, right click trên cửa sổ, chọn New Server Registration
[Hình ảnh: Hộp thoại Edit Server Registration Properties - General]
- Server Name : Nhập vào tên Server muốn đăng ký.
- Authentication:
	 + Windows Authentication: sử dụng user name của Win làm login name
	 + SQL Server Authentication: đặt 1 login name và 1 password để truy cập tới SQL Server .

[Hình ảnh: Hộp thoại Edit Server Registration Properties - Connection Properties]
 
**Hủy đăng ký :** Muốn hủy thông tin đăng ký, right click trên tên Server , chọn Delete.

## IV. THIẾT LẬP CÁC THUỘC TÍNH CỦA SERVER: 
Lệnh: Trong cửa sổ Object Explorer, right click trên tên server / Properties
Cửa sổ thuộc tính của server có 8 tabs: General, Memory, Processors, Security, Connections, Database Settings, Advanced và Permissions.

**1. General :** cho ta biết thông tin của sản phẩm và thông tin về phần cứng cũng như hệ điều hành;
[Hình ảnh: Thuộc tính Server - General]

**2. Memory :** cho phép ta chỉ ra bộ nhớ cần thiết cho server họat động. Tốt nhất ta nên chấp nhận giá trị mặc định của SQL Server.
Ví dụ: Nếu ta đang chạy các application khác trên cùng 1 NT Server và muốn giới hạn bộ nhớ tối đa mà SQL Server dùng thì điều chỉnh trong Maximum (MB)
[Hình ảnh: Thuộc tính Server - Memory]
 
**3. Processor :** chỉ ra SQL Server dùng 1 con vi xử lý hay nhiều con vi xử lý như thế nào? Trong 1 môi trường đa xử lý, ta có thể chỉ ra SQL Server sử dụng con vi xử lý nào. 
[Hình ảnh: Thuộc tính Server - Processor]

**4. Security :** cho phép ta xác định quyền vào SQL Server.
[Hình ảnh: Thuộc tính Server - Security]

**5. Connection :** cung cấp các options cho việc kết nối giữa client và remote server, và các thiết lập mặc định khi thực thi các thủ tục trên Server.
[Hình ảnh: Thuộc tính Server - Connections]

**6. Database setting :** cho phép ta chỉ ra giá trị mặc định trong việc tạo index, thực hiện việc backup/restoring dữ liệu . 
[Hình ảnh: Thuộc tính Server - Database Settings]

**7. Advanced:** [Hình ảnh: Thuộc tính Server - Advanced]

## V. QUẢN LÝ CƠ SỞ DỮ LIỆU VÀ CÁC ĐỐI TƯỢNG CƠ SỞ DỮ LIỆU:
**1. Tạo mới cơ sở dữ liệu :** Tạo cơ sở dữ liệu QLVT để chứa các Table : Right click folder Database / New Database
**General :** ta nhập vào tên cơ sở dữ liệu ở textbox Database Name
[Hình ảnh: Hộp thoại New Database - General]
Nút lệnh Add cho phép thêm file vào cơ sở dữ liệu.
Click …
[Hình ảnh: Tùy chọn Autogrowth Maxsize]
cho phép ta thiết lập cách thức SQL Server sẽ cấp phát thêm dung lượng cho file để lưu dữ liệu.
[Hình ảnh: Hộp thoại Change Autogrowth]

**Option :**
[Hình ảnh: Hộp thoại New Database - Options]
 
 **Options:**
-  Restrict access: giới hạn quyền truy xuất dữ liệu.	 
    + Restricted Users : chỉ có các user là thành viên của các nhóm db_owner, dbcreator, or sysadmin mới được sử dụng cơ sở dữ liệu (đề nghị : chọn khi cần)
	+ Single user : tại 1 thời điểm, chỉ 1 user được truy xuất cơ sở dữ liệu (đề nghị : chọn khi cần)
	+ Multi User : giá trị mặc định
- Database Read-Only = True : các user chỉ được quyền lấy dữ liệu từ cơ sở dữ liệu nhưng không được hiệu chỉnh. (đề nghị : chọn khi cần)
	
**2. Các folder trong cơ sở dữ liệu :**
Ta có thể thực hiện 1 số thao tác chung trên các folder hay trên các đối tượng của chúng:
- Tạo 1 đối tượng mới : right click trên folder / New <Object>
- Hiển thị hay thay đổi thuộc tính của đối tượng : double click trên đối tượng.
- Copy table, view, diagram : Right click / copy
- Đổi tên Table, View, Stored Procedure, Rule , Default … : Right click / Rename
- Xóa đối tượng: chọn đối tượng, ấn phím Del hay Right click/Delete

**a. Tạo Table :** cho phép ta định nghĩa tên field và thuộc tính của field
Ví dụ: Tạo cấu trúc Table Sinhvien:
[Hình ảnh: Cửa sổ Table Designer cho Table SINHVIEN]

* Các kiểu dữ liệu của Field:
	 Bit 	 : 0, 1
	 Binary (length) 	 : 1.. 8000 bytes (Fix)
	 VarBinary(max_length) 	 : 1..8000 bytes
	Image 	 : lên tới 2,147,483,647 bytes
	 Char, nChar (length) 	 : 1.. 8000 bytes (Fix)
	Varchar, nVarchar (max_length) 	 : 1..8000 bytes
	Text, nText 	 : lên tới 2,147,483,647 bytes
	 Dec (precision, scale) 	 : precision là số các chữ số (1..38). scale là số các chữ số bên phải dấu chấm thập phân (0.. precision)
	 TinyInt 	 : 1 byte , 0..255
	 SmallInt 	 : 2 bytes, -32768.. 32767
	 Int  	 : bốn bytes, -2,147,483,648.. 2,147,483,647
	 Float 	 : số bit để biểu diễn số thực động
	 Double Precision 	 : giống với float
	 Real 	 : tương đương với Float(24), có 7 chữ số phần nguyên
	 SmallMoney 	 : có 4 chữ số phần thập phân (-214,748.3648 .. 214,748.3647)
	 Money 		 : có 8 chữ số phần thập phân (922,337,203,685,477.5808 922,337,203,685,477.5807)
	 SmallDateTime 		 : 1-1-1900 .. 6-6-2079
	 Date Time 		 : 1-1-1753 .. 31-12-9999

Để cấp quyền truy cập table SINHVIEN : vào trang thuộc tính của table, chọn Permission, chọn user muốn cấp quyền:
[Hình ảnh: Hộp thoại Table Properties - Permissions]

Nếu ta click trên nút lệnh Column Permissions thì ta sẽ phân quyền trên từng cột của Table:
[Hình ảnh: Hộp thoại Column Permissions]

**b. Thay đổi cấu trúc table :** Right click trên tên table / Design Table
Hiện lại cửa sổ như ta nhập cấu trúc mới cho table.

**c. Xóa table :** Right click trên tên tabler muốn xóa, chọn Delete

**d. Đổi tên table :** Right click trên tên tabler muốn đổi tên, chọn Rename.

**e. Các đối tượng cơ sở dữ liệu thường dùng:**
- View, Stored Procedure, Function: lưu tên các đối tượng xử lý dữ liệu của cơ sở dữ liệu.
- Security: lưu tên các nhóm (role), người dùng (user) được quyền xử lý dữ liệu của cơ sở dữ liệu.
[Hình ảnh: Object Explorer hiển thị các đối tượng cơ sở dữ liệu]
