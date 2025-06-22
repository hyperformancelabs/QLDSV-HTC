# Database – SQL Server 2022

## 1. Giới Thiệu

Thư mục **`database/`** chứa toàn bộ T-SQL cần thiết để khởi tạo & vận hành CSDL **QLDSV_HTC**. Mọi cấu phần (table, index, stored procedure, view, trigger, backup…) đều được tách thành file *.sql* rõ ràng và thực thi tuần tự thông qua **`sql_executor.py`** (backend) hoặc các **bash script** trong `scripts/`.

---

## 2. Cấu Trúc Thư Mục

```text
database/
├── 01-foundation/   # Tạo DB + cấu hình cấp instance (COLLATE, FILEGROUP…)
├── 02-schema/       # DDL – Table, Index
├── 03-security/     # Login, User, Role, Permission
├── 04-backup/       # Mặc định rỗng – lưu file .bak định kỳ
├── 05-data/         # DML seed data (khoa, lớp, sinh viên, …)
├── 06-functions/    # UDF (scalar/table-valued)
├── 07-procedures/   # Stored Procedure (Auth, Báo cáo, …)
├── 08-views/        # View hỗ trợ ứng dụng
├── 09-triggers/     # Trigger (audit, ràng buộc phức tạp)
├── backups/         # Thư mục runtime – mount volume chứa backup
├── docker-compose.yml
└── Dockerfile       # Build image MS SQL Server + tools18
```

---

## 3. Khởi Tạo & Migration

```bash
# Tạo container SQL Server, seed data & chạy toàn bộ script
$ ./scripts/start-database.sh --setup

# Reset sạch (xoá container + volume) ➜ tạo lại
$ ./scripts/start-database.sh --reset
```

Sau khi container hoạt động, có thể kết nối bằng:

```
server : localhost,1434
user   : sa
pass   : <MSSQL_SA_PASSWORD trong .env>
```

---

## 4. Quy Ước Script

1. **GO**: chia batch; `sql_executor.py` sẽ tự tách khi dùng ODBC.
2. **Biến thay thế**: Sử dụng `$(DB_NAME)`, `$(MSSQL_APP_USER)` …; executor sẽ tự thay thế từ `.env`.
3. **Tên đối tượng**: PascalCase (`SinhVien`, `LopTinChi`…), cột snake_case (`diem_gk`).
4. **Comment**: Dùng `--` (1 dòng) & `/* */` (nhiều dòng) để giải thích lý do, không mô tả hiển nhiên.

---

## 5. Backup & Phục Hồi

* Tạo device: `SP_Backup_CreateDevice` (WIP) hoặc dùng script `scripts/utils/db`.
* Backup tự động: (đang phát triển) – cron container side.
* Phục hồi Point-in-time: xem DESCRIPTION.md mục 5.b.

---

## 6. Kiểm Tra Sức Khoẻ

```bash
# Kiểm tra kết nối & ODBC driver
$ ./scripts/utils/db/db-health-check.sh

# Ping DB từ backend
$ curl http://localhost:8000/api/v1/health
```

---

## 7. Tips Phát Triển

* Tránh dùng **foreign key** – ràng buộc bằng trigger để dễ phân quyền.
* Luôn `SET NOCOUNT ON;` trong SP để giảm traffic.
* Cập nhật thống kê: `EXEC sp_updatestats;` sau Bulk Insert.
* Thêm chỉ mục **composite** trước khi tối ưu câu truy vấn.

---

© 2024 – Nhóm QLDSV-HTC