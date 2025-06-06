# QLDSV-HTC Database Management

Hệ thống quản lý database cho đồ án **Quản Lý Điểm Sinh Viên Theo Hệ Tín Chỉ** với cấu trúc modular và script quản lý mạnh mẽ.

## 📁 Cấu Trúc Thư Mục

```
database/
├── 01-foundation/          # Database và logins cơ bản
│   ├── 01-init-database.sql
│   └── 02-create-logins.sql
├── 02-schema/              # Tables, constraints, indexes
│   ├── 01-drop-tables.sql
│   ├── 02-create-tables.sql
│   └── 03-create-indexes.sql
├── 03-security/            # Roles, users, permissions
│   ├── 01-drop-users-roles.sql
│   ├── 02-create-roles.sql
│   ├── 03-create-users.sql
│   └── 04-set-permissions.sql
├── 04-backup/              # Backup devices và procedures
│   ├── 01-drop-backup-devices.sql
│   └── 02-create-backup-devices.sql
├── 05-data/                # Seed data và test data
│   ├── 01-clear-data.sql
│   └── 02-seed-basic-data.sql
├── 06-functions/           # User-defined functions
├── 07-procedures/          # Stored procedures
├── 08-views/               # Views cho báo cáo
└── 09-triggers/            # Business logic triggers
```

## 🚀 Quick Start

### 1. Setup Ban Đầu
```bash
# Từ thư mục project root
./scripts/setup/db/setup-database.sh
```

### 2. Quản Lý Hàng Ngày
```bash
# Kiểm tra trạng thái
./scripts/utils/db/db-health-check.sh

# Restart database
./scripts/utils/db/restart-db.sh

# Reset database (development)
./scripts/utils/db/reset-db.sh
```

## 🛠️ Database Management Commands

### Foundation Commands
- `init-db` - Khởi tạo database (DROP + CREATE)
- `create-logins` - Tạo SQL Server logins

### Schema Commands
- `drop-tables` - Drop tất cả tables
- `create-tables` - Tạo tất cả tables
- `create-indexes` - Tạo performance indexes
- `rebuild-schema` - Rebuild toàn bộ schema

### Security Commands
- `drop-security` - Drop users và roles
- `create-roles` - Tạo custom roles
- `create-users` - Tạo database users
- `set-permissions` - Cấu hình permissions
- `rebuild-security` - Rebuild toàn bộ security

### Data Commands
- `clear-data` - Xóa tất cả dữ liệu
- `seed-basic` - Insert test data cơ bản
- `reseed` - Clear + seed lại data

### Full Operations
- `full-setup` - Setup hoàn chỉnh
- `full-reset` - Reset và setup lại toàn bộ
- `dev-reset` - Reset nhanh cho development

### Utility Commands
- `status` - Hiển thị trạng thái database
- `test-connections` - Test kết nối tất cả users

## 👥 User Roles Theo Đề Bài

### PGV (Phòng Giáo Vụ)
- **Username:** `pgv_user`
- **Quyền:** Toàn quyền (db_owner)
- **Chức năng:** Tất cả operations

### KHOA
- **Username:** `khoa_user`
- **Quyền:** Hạn chế (không được nhập Khoa, Lớp, GV, SV)
- **Chức năng:** Nhập điểm, quản lý lớp tín chỉ

### SV (Sinh Viên)
- **Username:** `sv`
- **Quyền:** Chỉ đọc + đăng ký lớp tín chỉ
- **Chức năng:** Đăng ký lớp, xem điểm

### Application Backend
- **Username:** `qldsv_app`
- **Quyền:** Read/Write + backup operations
- **Chức năng:** FastAPI backend

## 🗃️ Database Schema

### Core Tables
1. **KHOA** - Departments
2. **LOP** - Classes
3. **SINHVIEN** - Students
4. **MONHOC** - Subjects
5. **GIANGVIEN** - Teachers
6. **LOPTINCHI** - Credit Classes
7. **DANGKY** - Course Registrations

### Key Features
- ✅ Vietnamese collation support
- ✅ Proper foreign key constraints
- ✅ Performance indexes
- ✅ Role-based security
- ✅ Backup devices configured
- ✅ Test data included

## 🔄 Development Workflow

### Thay Đổi Schema
```bash
# 1. Chỉnh sửa file SQL trong database/02-schema/
# 2. Rebuild schema
./scripts/utils/db/reset-db.sh
```

### Thay Đổi Permissions
```bash
# 1. Chỉnh sửa file SQL trong database/03-security/
# 2. Rebuild security
./scripts/utils/db/reset-db.sh
```

### Thay Đổi Test Data
```bash
# 1. Chỉnh sửa database/05-data/02-seed-basic-data.sql
# 2. Refresh data
./scripts/utils/db/reset-db.sh
```

## 💾 Backup & Restore

### Backup Devices
- **DEVICE_QLDSV_HTC** - Full backups
- **DEVICE_QLDSV_HTC_LOG** - Transaction log backups  
- **DEVICE_QLDSV_HTC_DIFF** - Differential backups

### Manual Backup Commands
```sql
-- Full backup
BACKUP DATABASE QLDSV_HTC TO DEVICE_QLDSV_HTC
WITH FORMAT, INIT, COMPRESSION;

-- Differential backup
BACKUP DATABASE QLDSV_HTC TO DEVICE_QLDSV_HTC_DIFF
WITH DIFFERENTIAL, COMPRESSION;

-- Transaction log backup
BACKUP LOG QLDSV_HTC TO DEVICE_QLDSV_HTC_LOG;
```

## 🎯 Use Cases Phổ Biến

### Testing Schema Changes
```bash
./scripts/utils/db/reset-db.sh
```

### Adding New Indexes
```bash
# Edit database/02-schema/03-create-indexes.sql
./scripts/utils/db/reset-db.sh
```

### Changing User Permissions
```bash
# Edit database/03-security/04-set-permissions.sql
./scripts/utils/db/reset-db.sh
```

### Fresh Start
```bash
./scripts/utils/db/reset-db.sh
```

## 🔍 Troubleshooting

### Container Issues
```bash
# Check container status
docker ps | grep qldsv

# View container logs
docker logs qldsv-sqlserver

# Restart container
docker-compose restart
```

### Connection Issues
```bash
# Test all connections
./scripts/utils/db/db-health-check.sh
```

### Permission Issues
```bash
# Rebuild security completely
./scripts/utils/db/reset-db.sh
```

## 📝 Notes

- Tất cả scripts đều có pattern **DROP trước CREATE** để hỗ trợ development
- Sử dụng `reset-db.sh` cho thay đổi thường xuyên
- Backup devices được tự động tạo và cấu hình
- Test data bao gồm đủ các trường hợp để test nghiệp vụ

## 🔗 Related Files

- `../.env` - Configuration
- `docker-compose.yml` - Container setup
- `Dockerfile` - Custom SQL Server image
- `health/healthcheck.sh` - Health monitoring 