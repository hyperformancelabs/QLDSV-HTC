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
./scripts/setup/initial-setup.sh
```

### 2. Quản Lý Hàng Ngày
```bash
# Xem tất cả commands
./scripts/database/db-manager.sh help

# Reset nhanh cho development (chỉ schema + data)
./scripts/database/db-manager.sh dev-reset

# Refresh test data
./scripts/database/db-manager.sh reseed

# Kiểm tra trạng thái
./scripts/database/db-manager.sh status
```

## 🛠️ Database Manager Commands

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
./scripts/database/db-manager.sh rebuild-schema

# 3. Refresh data nếu cần
./scripts/database/db-manager.sh reseed
```

### Thay Đổi Permissions
```bash
# 1. Chỉnh sửa file SQL trong database/03-security/
# 2. Rebuild security
./scripts/database/db-manager.sh rebuild-security
```

### Thay Đổi Test Data
```bash
# 1. Chỉnh sửa database/05-data/02-seed-basic-data.sql
# 2. Refresh data
./scripts/database/db-manager.sh reseed
```

## 🎯 Use Cases Phổ Biến

### Testing Schema Changes
```bash
./scripts/database/db-manager.sh dev-reset
```

### Adding New Indexes
```bash
# Edit database/02-schema/03-create-indexes.sql
./scripts/database/db-manager.sh create-indexes
```

### Changing User Permissions
```bash
# Edit database/03-security/04-set-permissions.sql
./scripts/database/db-manager.sh set-permissions
```

### Fresh Start
```bash
./scripts/database/db-manager.sh full-reset
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
./management/db-manager.sh test-connections

# Check database status
./management/db-manager.sh status
```

### Permission Issues
```bash
# Rebuild security completely
./scripts/database/db-manager.sh rebuild-security
```

## 📝 Notes

- Tất cả scripts đều có pattern **DROP trước CREATE** để hỗ trợ development
- Sử dụng `dev-reset` cho thay đổi thường xuyên
- Sử dụng `full-reset` khi cần reset hoàn toàn
- Backup devices được tự động tạo và cấu hình
- Test data bao gồm đủ các trường hợp để test nghiệp vụ

## 🔗 Related Files

- `../.env` - Configuration
- `docker-compose.yml` - Container setup
- `Dockerfile` - Custom SQL Server image
- `health/healthcheck.sh` - Health monitoring 