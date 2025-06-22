# CHƯƠNG 6. SAO LƯU VÀ PHỤC HỒI DỮ LIỆU
## (BACKUP & RESTORE)

Backup là công việc quan trọng cho mỗi Database Admin (DBA) để đảm bảo an toàn dữ liệu. Khi có sự cố xảy ra, backup file là nguồn duy nhất giúp ta khôi phục dữ liệu trở lại. Trong thời đại dữ liệu trở thành trung tâm của các hoạt động doanh nghiệp, mất mát dữ liệu làm ảnh hưởng nghiêm trọng, thậm chí làm tê liệt hoạt động của công ty. Vì thế không có gì ngạc nhiên khi trong các yêu cầu trách nhiệm của DBA, backup database luôn được liệt kê ở phần đầu.

## 1. SAO LƯU DỮ LIỆU:
Một backup đầy đủ là backup mọi thứ trong hệ thống :
*   Phần mềm hỗ trợ
*   Chương trình của user
*   Đối tượng cơ sở dữ liệu
*   Các tệp tin mà user tạo

Tuy nhiên, lệnh backup ở đây chỉ tạo bản sao của các đối tượng cơ sở dữ liệu như table, view, stored procedure, Function, Trigger, User, Role, Rule, Default, các ràng buộc, nhật ký các giao tác.

### 1. Thiết bị backup: có thể là:
*   File trên đĩa cục bộ
*   File trên mạng

** Cách tạo 1 thiết bị backup bằng Management Studio:**
Khởi động SQL Server Enterprise Management / Server Object. Right click trên Folder Backup / Chọn New Backup Device. Ta nhập vào tên logic đại diện cho device trong textbox Device Name, và chọn tên file để lưu trữ các bản sao. Một backup device có thể chứa nhiều bản sao lưu của nhiều cơ sở dữ liệu.

[Image Placeholder: Management Studio interface for creating a new backup device]

** Cách tạo 1 thiết bị backup bằng T-SQL:**
**Cú pháp:**
```sql
sp_addumpdevice [@devtype =] 'device_type', [@logicalname =] 'logical_name', [@physicalname =] 'physical_name'
```

**Các tham số:**
`[@devtype =] 'device_type'`, là kiểu của backup device. device_type là varchar(20) và thuộc 1 trong các trị sau:

| Value | Description                                  |
|-------|----------------------------------------------|
| Disk  | backup device là 1 file trên đĩa cứng cục bộ |
| Pipe  | backup device là 1 file trên đĩa cứng mạng.  |

`[@logicalname =] 'logical_name'`
là tên logic của backup device và được sử dụng trong các lệnh BACKUP và RESTORE.

**Giá trị mã trả về sau khi thực hiện sp_addumpdevice :**
0 (thành công) or 1 (thất bại)

**Ghi chú:**
sp_addumpdevice đưa 1 backup device vào bảng `master.dbo.sysdevices`, và ta có thể truy vấn từ view `sys.sysdevices` hoặc view `sys.backup_devices`. sp_addumpdevice không được thực hiện bên trong 1 transaction.

**Ví dụ 1 : Tạo 1 disk dump device**
Tạo 1 backup device có tên MYDISKDUMP, với file lưu là C:\Dump\Dump1.bak.
```sql
EXEC sp_addumpdevice 'disk', 'mydiskdump', 'c:\dump\dump1.bak'
```

**Ví dụ 2 : Tạo 1 disk backup device trên mạng**
Tạo 1 disk backup device ở xa. Tên file được đề cập ở đây phải được SQL Server có quyền truy xuất.
```sql
EXEC sp_addumpdevice ‘pipe’, 'networkdevice', '\\servername\sharename\path\filename.ext'
```
Muốn xóa device đã tạo:
```sql
sp_dropdevice [ @logicalname = ] 'device'
[ , [ @delfile = ] 'delfile' ]
```

Tham số ‘delfile’ cho phép xóa file backup tương ứng với backup device .
**Ví dụ : Xóa device MYDISKDUMP và file C:\Dump\Dump1.bak tương ứng**
```sql
EXEC sp_dropdevice 'MYDISKDUMP ', ‘delfile’.
```

### 2. Backup: Right click tên cơ sở dữ liệu /Tasks / Back Up…

[Image Placeholder: Management Studio interface for initiating a backup]

- **Backup type :**
    *   ⮲ **Full backup:** backup toàn bộ dữ liệu tại thời điểm đó, đây là loại backup được dùng thường xuyên nhất.
    *   ⮲ **Differential backup:** backup các trang dữ liệu mới được cập nhật kể từ lần full backup gần nhất trước đó.
    *   ⮲ **Transaction log backup:** backup các log record hiện có trong log file, nghĩa là nó sao lưu các hành động (các thao tác xảy ra trên database) chứ không sao lưu dữ liệu. Đồng thời nó cũng cắt bỏ (truncate) log file, loại bỏ các log record vừa được backup ra khỏi log file. Vì thế khi thấy log file tăng quá lớn, có nhiều khả năng là ta chưa từng backup transaction log bao giờ.
- **Destination:** chỉ ra các device hoặc tên file sẽ chứa bản backup
Ta click nút lệnh Add để chỉ định nơi chứa bản sao, ta có thể chọn nơi chứa dữ liệu backup có thể là 1 file hay 1 backup device đã định nghĩa trước.

[Image Placeholder: Management Studio interface for selecting backup destination]

**Lưu ý :** Nếu ta muốn xem nội dung của file hoặc device chứa các bản backup, ta chọn file hoặc device, sau đó click button Contents:

[Image Placeholder: Management Studio interface for viewing contents of a backup file/device]

**Cách backup bằng T-SQL: Cú pháp:**

**Backup toàn bộ database:**
```sql
BACKUP DATABASE {database_name | @database_name_var} TO <backup_device> [,...n]
[WITH
    [ DESCRIPTION = {text | @text_variable}] [[,] DIFFERENTIAL]
    [[,] NOINIT | INIT]
    [[,]NOSKIP | SKIP]
    [[,] EXPIREDATE = {date | @date_var}
        | RETAINDAYS = {days | @days_var}] [[,] STATS [= percentage]]
]
```
**Backup files or filegroups:**
```sql
BACKUP DATABASE {database_name | @database_name_var}
    <file_or_filegroup> [,...n] TO <backup_device> [,...n]
[WITH
    [ EXPIREDATE = {date | @date_var}
        | RETAINDAYS = {days | @days_var}] [[,] STATS [= percentage]]
]
```
**Backup a transaction log: (Backup Nhật ký các giao tác)**
```sql
BACKUP LOG {database_name | @database_name_var}
{
    [WITH TRUNCATE_ONLY ]
}
{
    TO <backup_device> [,...n]
    [WITH
        [INIT] [NORECOVERY] [NO_TRUNCATE]
        [[,] STATS [= percentage]]
    ]
}
```
**Tham số:**
*   **DATABASE**
    Chỉ ra backup database. Nếu ta chỉ ra 1 danh sách files và filegroups, thì chỉ có các file này được backup.
*   **database_name** : là tên của cơ sở dữ liệu được backup
*   **<backup_device>** : là tên logic của backup device được tạo bởi sp_addumpdevice, hoặc là tên file vật lý bắt đầu với ‘DISK’.
*   **n** :cho biết backup cơ sở dữ liệu vào nhiều backup devices. Số backup devices tối đa là 32.
*   **DIFFERENTIAL**: các trang dữ liệu mới được cập nhật kể từ lần full backup gần nhất trước đó (mặc định là backup Full)
*   **NOSKIP**: yêu cầu lệnh BACKUP kiểm tra ngày hết hạn và tên của tất cả các bộ sao lưu trước khi cho phép chúng bị ghi đè (giá trị mặc định)
*   **INIT**: bản backup mới nhất sẽ ghi đè lên file hiện tại. Nếu có một bản sao lưu chưa hết hạn, thao tác sao lưu sẽ không thành công. Trong trường hợp này, sử dụng kết hợp các tùy chọn SKIP và INIT để ghi đè lên backup device. Nếu không có “WITH INIT” này, các bản backup sẽ được ghi nối tiếp nhau trong cùng một file. Sau này, ta có thể cho phục hồi cơ sở dữ liệu về bản backup thứ i (lưu trong thuộc tính position). Mặc định là NOINIT.
*   **NO_TRUNCATE**: dùng NO_TRUNCATE nếu ta muốn sao lưu nhật ký giao dịch mà không cắt bớt nó - nghĩa là, tùy chọn này không xóa các giao tác đã commit trong nhật ký. Sau khi thực hiện tùy chọn này, hệ thống ghi tất cả các hoạt động cơ sở dữ liệu gần đây vào nhật ký giao tác. Do đó, tùy chọn NO_TRUNCATE sẽ cho phép ta khôi phục dữ liệu ngay đến thời điểm cơ sở dữ liệu có sự cố.
*   **NORECOVERY**: Backup... với norecovery sẽ tiến hành sao lưu rồi đưa cơ sở dữ liệu về trạng thái ‘restoring’. Thường option này được sử dụng nếu thực hiện sao lưu nhật ký trước khi bắt đầu phục hồi. Nó sẽ sao lưu cơ sở dữ liệu và sau đó thay đổi trạng thái cơ sở dữ liệu từ ONLINE sang ‘RESTORING’. Ở trạng thái đó, không ai có thể truy cập được vào cơ sở dữ liệu. Nếu ta sao lưu nhật ký trước khi phục hồi, ta không muốn thực hiện thêm bất kỳ thay đổi nào sau lần sao lưu nhật ký cuối cùng.

**Ví dụ:**
1.  **Back up toàn bộ cơ sở dữ liệu:**
    Câu lệnh sau sẽ tạo 1 backup device tên MyNwind_1 chứa full database backup của cơ sở dữ liệu MyNwind database.
    ```sql
    -- Create the backup device for the full MyNwind backup.
    USE master
    EXEC sp_addumpdevice 'disk', 'MyNwind_1', 'c:\backup\MyNwind_1.dat'
    -- Back up the full MyNwind database.
    BACKUP DATABASE MyNwind TO MyNwind_1
    ```
2.  **Back up toàn bộ cơ sở dữ liệu và log**
    Ví dụ sau đây sao lưu cả database và file nhật ký. Database được lưu đến 1 backup device tên MyNwind_2, và file nhật ký được backup đến 1 file tên MyNwindLog1.
    ```sql
    -- Create the backup device for the full MyNwind backup.
    USE master
    EXEC sp_addumpdevice 'disk', 'MyNwind_2', 'c:\backup\MyNwind_2.dat'
    -- Back up the full MyNwind database.
    BACKUP DATABASE MyNwind TO MyNwind_2
    -- Create the log backup device.
    USE master
    EXEC sp_addumpdevice 'disk', 'MyNwindLog1', 'c:\backup\MyNwindLog1.dat'
    -- Update activity has occurred before this point.
    -- Back up the log of the MyNwind database.
    BACKUP LOG MyNwind TO MyNwindLog1
    ```
3.  **Back up toàn bộ cơ sở dữ liệu vào file:** Sao lưu cơ sở dữ liệu QLDSV vào file.
    ```sql
    BACKUP DATABASE QLDSV TO DISK = ‘D:\BACKUP\QLDSV.BAK’
    ```
**Quyền thực hiện:**
Chỉ các user là thành viên của nhóm db_owner và db_backupoperator mới được quyền thực hiện BACKUP DATABASE và BACKUP LOG.

**Thông tin các bản backup được lưu trong :**
*   `msdb.dbo.Backupset`
```sql
SELECT backup_set_id, media_set_id, position, backup_start_date, backup_finish_date, type, database_name, user_name FROM MSDB.dbo.backupset
```
Media_set_id : là id của device backup mới nhất lưu các bản backup của cơ sở dữ liệu.

### 3. Tổ chức backup:
1.  Các sự kiện đòi hỏi phải backup cơ sở dữ liệu hệ thống: khi ta thao tác 1 số lệnh sau trên cơ sở dữ liệu `master`.
    *   Tạo, thay đổi, xóa cơ sở dữ liệu
    *   Tạo thay đổi, xóa 1 filegroup
    *   Thay đổi cấu hình của server hay cơ sở dữ liệu.
2.  Các sự kiện đòi hỏi phải backup cơ sở dữ liệu của user:
    *   Tạo cơ sở dữ liệu
    *   Thay đổi cấu trúc của cơ sở dữ liệu
    *   Tạo Index
    *   Định kỳ

### 4. Tạo SQL Job Dùng Để Backup Database tự động:
Ta có thể tạo 1 Job để sao lưu cơ sở dữ liệu tự động một cách dễ dàng thông qua dịch vụ SQL Server Agent. Đây là đối tượng trong SQL Server dùng để tự động thực hiện các tác vụ, tương tự như Scheduled Task của Windows. Giả sử ta muốn tạo 1 Job tự động sao lưu cơ sở dữ liệu QUANLYDIEMSV, vào lúc 1h đêm mỗi ngày.

Trong Management Studio, ta mở rộng nút “SQL Server Agent”, sau đó click phím phải vào nút “Jobs”, rồi chọn “New Job…”:

[Image Placeholder: Management Studio - SQL Server Agent context menu]

[Image Placeholder: Management Studio - New Job dialog window general tab]

Sau đó ở hàng menu bên trái, click chuột vào dòng “Steps”, rồi bấm vào nút “New…”, cửa sổ New Job Step hiện ra . Ở cửa sổ mới này, ở ô “Step name” ta nhập “Backup”, để nguyên các ô còn lại, và ở phần soạn thảo “Command” hãy nhập đoạn code sau:
```sql
BACKUP DATABASE QUANLYDIEMSV TO DEVICE_QUANLYDIEMSV
```

[Image Placeholder: Management Studio - New Job Step dialog window]

Sau khi nhập xong, ta click OK và trở lại màn hình ban đầu. Giờ ở hàng menu bên trái, ta chọn “Schedules” và click vào “New…” để tạo một lịch làm việc cho Job:

[Image Placeholder: Management Studio - New Job Schedule dialog window]

Ở ô “Name” ta nhập vào “Backup – Daily”; ở ô “Occurs” ta chọn “Daily” và “Occurs once at:” ta chọn “1:00:00 AM”; các phần khác giữ nguyên. Như vậy backup job sẽ chạy hàng ngày vào lúc 1h sáng.
Sau đó ta click “OK” để trở về màn hình trước và click “OK” lần nữa để quay trở lại Management Studio. Việc thiết lập như vậy là đã xong, ta đã tạo được một job có tên “Backup – Daily-QUANLYDIEMSV” để backup database và sẽ được chạy hàng ngày vào lúc 1h sáng.

[Image Placeholder: Management Studio - Job successfully created]

## 2. PHỤC HỒI CƠ SỞ DỮ LIỆU (RESTORE DATABASE):
SQL Server phục hồi cơ sở dữ liệu qua 2 bước:
*   Xóa cơ sở dữ liệu lưu dữ liệu phục hồi (nếu đã có trong server). Do đó, nếu ta muốn phục hồi đè lên cơ sở dữ liệu đang có trong Server thì phải ngắt tất cả kết nối đến cơ sở dữ liệu.
*   Tạo mới cơ sở dữ liệu để lưu dữ liệu trong file backup.

### 1. Phục hồi cơ sở dữ liệu từ giao diện:
Right click trên cơ sở dữ liệu muốn restore / Tasks / Restore/ Database.
*   **Tab General:**

[Image Placeholder: Management Studio - Restore Database - General tab]

Sau khi chọn device, ta click chọn 1 bản sao lưu để phục hồi dữ liệu .
*   **Tab Option:**

[Image Placeholder: Management Studio - Restore Database - Options tab]

### 2. Restore cơ sở dữ liệu từ câu lệnh:
**Cú pháp:**
```sql
RESTORE DATABASE {database_name | @database_name_var} [FROM <backup_device> [,...n]]
[WITH
    [DBO_ONLY]
    [[,] NORECOVERY]
    [[,] REPLACE]
    [[,] FILE = <position>]
```

**Restore specific files or filegroups:**
```sql
RESTORE DATABASE {database_name | @database_name_var}
    <file_or_filegroup> [,...n] [FROM <backup_device> [,...n]]
[WITH
    [DBO_ONLY]
    [[,]STOPAT =time]
    [[,] NORECOVERY]
    [[,] REPLACE]
```

**Restore a transaction log:**
```sql
RESTORE LOG {database_name | @database_name_var} [FROM <backup_device> [,...n]]
[WITH
    [DBO_ONLY]
    [[,]STOPAT =time]
    [[,] NORECOVERY]
```

**Tham số:**
*   **DATABASE**
    Phục hồi hoàn toàn database từ 1 backup. Nếu ta chỉ ra 1 danh sách files và filegroups, thì chỉ có các file này được phục hồi.
*   **{database_name }**
    Là cơ sở dữ liệu chứa dữ liệu sau khi được phục hồi.
*   **FROM**
    Chỉ ra backup devices chứa dữ liệu backup
*   **DBO_ONLY**
    Việc phục hồi cơ sở dữ liệu chỉ dành cho người sở hữu cơ sở dữ liệu (database owner) Option này được sử dụng với RECOVERY option.
*   **STOPAT =time** : Điểm phục hồi là giao tác được commit mới nhất xảy ra vào hoặc trước giá trị ngày giờ được chỉ định theo time
*   **NORECOVERY**
    Chỉ ra thao tác restore không cho dữ liệu được rollback với các giao tác chưa được xác nhận (uncommitted), cơ sở dữ liệu ở trạng thái không hoạt động. Option NORECOVERY phải được dùng nếu có 1 file nhật ký các giao tác đã được áp dụng. RECOVERY là giá trị mặc định.
    SQL Server yêu cầu option WITH NORECOVERY được dùng trên tất cả các lệnh RESTORE ngoại trừ lệnh RESTORE sau cùng. RESTORE Database WITH NORECOVERY đặt cơ sở dữ liệu vào trạng thái ‘restoring’, để tiếp tục restore từ các bản backups, và users không thể truy xuất cơ sở dữ liệu ở trạng thái này.
    RESTORE Database WITH RECOVERY sẽ bỏ qua các giao tác chưa được xác nhận, đưa cơ sở dữ liệu về lại trạng thái ‘online’ để các user sử dụng.
*   **REPLACE**
    SQL Server sẽ tạo ra 1 database và các files có liên hệ. Trong trường hợp tên cơ sở dữ liệu sau khi restore trùng tên với 1 cơ sở dữ liệu trên server thì cơ sở dữ liệu đó sẽ bị xóa. Khi option REPLACE không được chỉ ra, 1 cơ chế an toàn sẽ hoạt động (không cho phép chồng lên 1 cơ sở dữ liệu khác).
*   **FILE = n** : n là 1 số nguyên chỉ định lệnh Restore sẽ phục hồi cơ sở dữ liệu về bản backup thứ mấy trong `msdb.dbo.backupset.position`
*   **LOG**
    Chỉ ra restore từ 1 bản backup transaction log. Transaction logs phải được áp dụng tuần tự theo thứ tự thời gian. Nếu có nhiều transaction logs, ta dùng option NORECOVERY trên tất cả các lệnh restore, ngoại trừ lệnh sau cùng.

**Lưu ý:**
Trong quá trình restore, database phải ở trạng thái không được sử dụng. Tất cả dữ liệu trong database mà ta chỉ ra trong lệnh restore sẽ được thay thế.

**Restore Types**
Dưới đây là 1 số kiểu restores mà SQL Server hỗ trợ:
*   Full database restore : phục hồi toàn bộ database.
*   Full database restore về differential database restore: phục hồi 1 differential backup
*   Transaction log restore: phục hồi từ file nhật ký

**Quyền sử dụng:**
Nếu database được phục hồi không có, user phải có quyền sử dụng lệnh CREATE DATABASE. Nếu database đã có, user sử dụng lệnh RESTORE phải là thành viên của nhóm sysadmin và nhóm db_owner.

**Ví dụ:**
**Ghi chú:** Tất cả ví dụ dưới đây được thực hiện với giả sử 1 lệnh full database backup đã được thực hiện trước đó.

1.  **Restore a full database**
    Note: Cơ sở dữ liệu MyNwind được giả sử là đã có
    Ví dụ sau đây sẽ phục hồi 1 full database backup.
    ```sql
    RESTORE DATABASE MyNwind FROM MyNwind_1
    ```
2.  **Restore a full database and a differential backup**
    Ví dụ này phục hồi dữ liệu trên 1 bản full database backup , sau đó phục hồi trên 1 differential backup. The differential backup được nối thêm vào bản backup đang chứa 1 full database backup.
    ```sql
    RESTORE DATABASE MyNwind
        FROM MyNwind_1 WITH NORECOVERY
    RESTORE DATABASE MyNwind
        FROM MyNwind_1 WITH FILE = 2
    ```
3.  **Restore a database using RESTART syntax**
    Ví dụ này dùng option RESTART để khởi động lại tiến trình RESTORE khi tiến trình này bị ngắt bởi lỗi server.
    ```sql
    RESTORE DATABASE MyNwind
        FROM MyNwind_1
    -- Here is the RESTORE RESTART operation.
    RESTORE DATABASE MyNwind
        FROM MyNwind_1 WITH RESTART
    ```
4.  **Restore a database and move files**
    Ví dụ sau đây sẽ phục hồi 1 full database and transaction log, và di chuyển cơ sở dữ liệu đã được phục hồi qua thư mục C:\Mssql7\Data directory.
    ```sql
    RESTORE DATABASE MyNwind
        FROM MyNwind_1 WITH NORECOVERY,
        MOVE 'MyNwind' TO 'c:\mssql7\data\NewNwind.mdf',
        MOVE 'MyNwindLog1' TO 'c:\mssql7\data\NewNwind.ldf'
    RESTORE LOG MyNwind
        FROM MyNwindLog1 WITH RECOVERY
    ```
5.  **Restore using DISK syntax**
    Restores 1 full database backup từ 1 DISK backup device.
    ```sql
    RESTORE DATABASE MyNwind
        FROM DISK = 'c:\backup\MyNwind.bak'
    ```
6.  **Restore using FILE and FILEGROUP syntax**
    Ví dụ sau đây minh họa việc restore 1 database với 2 files, 1 filegroup, và 1 transaction log.
    ```sql
    RESTORE DATABASE MyNwind
        FILE = 'MyNwind_data_1',
        FILE = 'MyNwind_data_2',
        FILEGROUP = 'new_customers'
        FROM MyNwind_1 WITH NORECOVERY
    -- Restore the log backup.
    RESTORE LOG MyNwind
        FROM MyNwindLog1
    ```

### 3. Phục hồi cơ sở dữ liệu về thời điểm chưa backup:
Để có thể khôi phục lại cơ sở dữ liệu trong trường hợp này, cơ sở dữ liệu phải đáp ứng ba điều kiện sau:
*   Database có chế độ RECOVERY MODE là FULL
*   Database đã từng được FULL BACKUP và ta có trong tay file backup gần nhất
*   Log file chưa từng bị SHRINK kể từ sau lần full backup gần nhất.

Nếu một trong ba điều kiện trên bị vi phạm thì vấn đề kể như hết cách giải cứu.
Vấn đề đặt ra ở đây là khi có sự cố trên cơ sở dữ liệu (thời điểm t2) mà bản sao lưu mới nhất lại cách thời điểm đó vài tuần (thời điểm t1 , với t1< t2 ) thì làm cách nào ta có thể phục hồi cơ sở dữ liệu về thời điểm t trước khi xảy ra sự cố (t1 < t < t2).

Giả sử cả ba điều kiện trên được thỏa mãn và lần full backup gần đây nhất là đêm hôm trước. Ta có thể khôi phục thông qua các bước sau :
1.  Đóng lại tất cả các kết nối đến database để không tiếp nhận thêm dữ liệu
2.  Ghi lại thời điểm xảy ra lệnh DELETE lỗi
3.  Thực hiện BACKUP LOG cho database
4.  Khôi phục lại database theo trình tự sau:
    *   RESTORE từ bản full backup đêm hôm trước
    *   RESTORE từ bản log backup với lựa chọn STOPAT = thời điểm ngay trước khi có sự cố.
5.  Và khi mọi việc đã hoàn tất, chuyển lại database sang chế độ hoạt động bình thường để các ứng dụng lại có thể kết nối vào database.

**Ví dụ:**
*   Bản backup thứ 1 lúc 2:21 PM 4/12/18 (vật tư MX01 ..TV02). (có 5 vật tư)
    ```sql
    BACKUP DATABASE QLVT TO DISK = 'D:\Backup\QLVT.bak' WITH INIT
    ```
*   LÚC 3:00 PM , 4/12/18 thêm vật tư (TL01, Tủ lạnh Pana) , vật tư này không có trong backup thứ 1.
*   Xóa table KHO lúc 7:30 AM 5/12/18
    ```sql
    DELETE FROM KHO
    ```
*   Phục hồi DB về thời điểm 7:20 AM 5/12/18; lúc này cơ sở dữ liệu sau khi được phục hồi vẫn giữ được vật tư TL01 và phục hồi lại table KHO
    ```sql
    BACKUP LOG QLVT TO DISK = 'D:\backup\QLVT.trn' WITH INIT
    ```
    Phục hồi lại database theo thứ tự bản full backup trước rồi đến bản log backup:
    ```sql
    RESTORE DATABASE QLVT FROM DISK = 'D:\backup\QLVT.bak' WITH NORECOVERY
    RESTORE LOG QLVT FROM DISK = 'D:\backup\QLVT.trn' WITH STOPAT='2018-12-05 07:20:00'
    ALTER DATABASE QLVT SET MULTI_USER
    ```
Điểm mấu chốt trong đoạn lệnh trên là mệnh đề STOPAT ở lệnh RESTORE thứ hai. Mục đích của nó là khôi phục lại database từ log backup nhưng dừng lại tại thời điểm được chỉ định. Khi các hành động xảy ra đối với database được lưu vào log file, nó cũng kèm theo thời điểm xảy ra hành động đó. Khi backup log file thì bản backup cũng chứa y nguyên các thông tin này. Vì thế khi restore từ log file với mệnh đề STOPAT, ta đã yêu cầu hệ thống THỰC HIỆN lại các hành động đã được áp dụng đối với database, nhưng dừng lại trước thời điểm có sự cố. Do đó lệnh DELETE trên không được thực hiện lại và bảng đã trở về trạng thái như cũ.
Hãy để ý ở mệnh đề STOPAT, ta đã lùi thời gian lại một chút để đảm bảo thời điểm đó là trước khi xảy ra xóa dữ liệu. Cuối cùng, ta chuyển cơ sở dữ liệu về trạng thái cho sử dụng lại.

## Bài tập:
1.  Sau khi backup, thông tin về device backup, thông tin về các bản backup được lưu trữ trong các table hệ thống nào?
2.  Viết 1 SP liệt kê ra màn hình [ngày giờ backup], [thứ tự backup] , [user thực hiện] của 1 cơ sở dữ liệu có tên do ta chỉ ra.

---

## Trả lời Bài tập:

1.  **Sau khi backup, thông tin về device backup, thông tin về các bản backup được lưu trữ trong các table hệ thống nào?**

    Dựa vào nội dung tài liệu:
    *   Thông tin về device backup (được tạo bằng `sp_addumpdevice`) được đưa vào bảng `master.dbo.sysdevices`. Tài liệu cũng đề cập có thể truy vấn từ view `sys.sysdevices` hoặc view `sys.backup_devices`.
    *   Thông tin các bản backup được lưu trong bảng `msdb.dbo.Backupset`.

2.  **Viết 1 SP liệt kê ra màn hình [ngày giờ backup], [thứ tự backup] , [user thực hiện] của 1 cơ sở dữ liệu có tên do ta chỉ ra.**

    Dựa trên truy vấn mẫu được cung cấp trong tài liệu (`SELECT backup_set_id, media_set_id, position, backup_start_date, backup_finish_date, type, database_name, user_name FROM MSDB.dbo.backupset`), ta có thể xây dựng Stored Procedure (SP) như sau:
    *   `[ngày giờ backup]` tương ứng với cột `backup_start_date`.
    *   `[thứ tự backup]` tương ứng với cột `position` (là vị trí của bản backup trong media set).
    *   `[user thực hiện]` tương ứng với cột `user_name`.

    ```sql
    CREATE PROCEDURE sp_LietKeLichSuBackup
        @TenCSDL NVARCHAR(128)
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            bs.backup_start_date AS [Ngày Giờ Backup],
            bs.position AS [Thứ Tự Backup],
            bs.user_name AS [User Thực Hiện]
        FROM
            msdb.dbo.backupset bs
        WHERE
            bs.database_name = @TenCSDL
        ORDER BY
            bs.backup_start_date DESC; -- Sắp xếp theo ngày giờ backup gần nhất lên đầu
    END
    GO

    -- Cách sử dụng:
    -- EXEC sp_LietKeLichSuBackup @TenCSDL = 'TenDatabaseCuaBan';
    -- Ví dụ:
    -- EXEC sp_LietKeLichSuBackup @TenCSDL = 'MyNwind';
    -- EXEC sp_LietKeLichSuBackup @TenCSDL = 'QLDSV';
    ```