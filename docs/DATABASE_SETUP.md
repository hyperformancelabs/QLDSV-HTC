# QLDSV-HTC Database Management Guide

Hướng dẫn quản lý database cho hệ thống **Quản Lý Điểm Sinh Viên Theo Hệ Tín Chỉ** với SQL Server và Docker.

## 📋 Tổng Quan

### Kiến Trúc Database
- **Database Engine**: SQL Server 2022 (Docker)
- **Database Name**: QLDSV_HTC
- **Collation**: Vietnamese_CI_AS
- **Management**: Script-based với automation

### Cấu Trúc Tổ Chức
```
database/                    # SQL files và configuration
├── 01-foundation/          # Database và logins cơ bản
├── 02-schema/              # Tables, constraints, indexes
├── 03-security/            # Roles, users, permissions
├── 04-backup/              # Backup devices
├── 05-data/                # Seed data và test data
├── 06-functions/           # User-defined functions
├── 07-procedures/          # Stored procedures
├── 08-views/               # Views cho báo cáo
└── 09-triggers/            # Business logic triggers

scripts/database/           # Management scripts
├── db-manager.sh          # Script quản lý chính
├── db-setup.sh            # Initial setup
├── db-health.sh           # Health monitoring
└── db-mgmt.sh             # Console wrapper
```

## 🚀 Quick Start

### 1. Setup Ban Đầu
```bash
# Từ project root
./scripts/setup/initial-setup.sh
```

### 2. Kiểm Tra Trạng Thái
```bash
./scripts/database/db-manager.sh status
```

### 3. Test Connections
```bash
./scripts/database/db-manager.sh test-connections
```

## 🛠️ Database Manager Commands

### Foundation Commands
```bash
./scripts/database/db-manager.sh init-db              # Initialize database
./scripts/database/db-manager.sh create-logins        # Create SQL Server logins
```

### Schema Management
```bash
./scripts/database/db-manager.sh drop-tables          # Drop all tables
./scripts/database/db-manager.sh create-tables        # Create all tables
./scripts/database/db-manager.sh create-indexes       # Create performance indexes
./scripts/database/db-manager.sh rebuild-schema       # Full schema rebuild
```

### Security Management
```bash
./scripts/database/db-manager.sh drop-security        # Drop users and roles
./scripts/database/db-manager.sh create-roles         # Create custom roles
./scripts/database/db-manager.sh create-users         # Create database users
./scripts/database/db-manager.sh set-permissions      # Configure permissions
./scripts/database/db-manager.sh rebuild-security     # Full security rebuild
```

### Data Management
```bash
./scripts/database/db-manager.sh clear-data           # Clear all data
./scripts/database/db-manager.sh seed-basic           # Insert test data
./scripts/database/db-manager.sh reseed               # Clear + seed data
```

### Full Operations
```bash
./scripts/database/db-manager.sh full-setup           # Complete setup
./scripts/database/db-manager.sh full-reset           # Complete reset
./scripts/database/db-manager.sh dev-reset            # Quick development reset
```

### Utility Commands
```bash
./scripts/database/db-manager.sh status               # Show database status
./scripts/database/db-manager.sh test-connections     # Test all connections
./scripts/database/db-manager.sh help                 # Show all commands
```

## 👥 User Management

### User Roles Theo Đề Bài

| Role | Username | Permissions | Mô Tả |
|------|----------|-------------|-------|
| **PGV** | `pgv_user` | Full access (db_owner) | Phòng Giáo Vụ - Toàn quyền |
| **KHOA** | `khoa_user` | Limited access | Khoa - Không được nhập Khoa, Lớp, GV, SV |
| **SV** | `sv` | Read + Registration | Sinh Viên - Đăng ký lớp, xem điểm |
| **APP** | `qldsv_app` | Backend access | Application backend |

### Connection Information
```
Server: localhost,1433
Database: QLDSV_HTC
Authentication: SQL Server Authentication
```

### Connection Strings
```python
# FastAPI Backend
DATABASE_URL = "mssql+pyodbc://qldsv_app:App%402024%21@localhost:1433/QLDSV_HTC?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes"

# Direct pyodbc
connection_string = (
    "DRIVER={ODBC Driver 18 for SQL Server};"
    "SERVER=localhost,1433;"
    "DATABASE=QLDSV_HTC;"
    "UID=qldsv_app;"
    "PWD=App@2024!;"
    "TrustServerCertificate=yes"
)
```

## 🗃️ Database Schema

### Core Tables
1. **KHOA** - Departments/Faculties
2. **LOP** - Classes  
3. **SINHVIEN** - Students
4. **MONHOC** - Subjects/Courses
5. **GIANGVIEN** - Lecturers
6. **LOPTINCHI** - Credit Classes
7. **DANGKY** - Course Registrations

### Key Features
- ✅ Vietnamese collation support
- ✅ Proper foreign key constraints with CASCADE options
- ✅ Performance indexes for common queries
- ✅ Role-based security model
- ✅ Backup devices configured
- ✅ Comprehensive test data

## 🔄 Development Workflow

### Thay Đổi Schema
```bash
# 1. Chỉnh sửa files trong database/02-schema/
# 2. Rebuild schema
./scripts/database/db-manager.sh rebuild-schema

# 3. Refresh data nếu cần
./scripts/database/db-manager.sh reseed
```

### Thay Đổi Permissions
```bash
# 1. Chỉnh sửa files trong database/03-security/
# 2. Rebuild security
./scripts/database/db-manager.sh rebuild-security
```

### Thay Đổi Test Data
```bash
# 1. Chỉnh sửa database/05-data/02-seed-basic-data.sql
# 2. Refresh data
./scripts/database/db-manager.sh reseed
```

### Development Reset (Thường Dùng Nhất)
```bash
# Reset nhanh cho development (chỉ schema + data)
./scripts/database/db-manager.sh dev-reset
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

### Daily Development
```bash
# Check status
./scripts/database/db-manager.sh status

# Refresh test data
./scripts/database/db-manager.sh reseed

# Quick reset
./scripts/database/db-manager.sh dev-reset
```

## 🔍 Monitoring & Troubleshooting

### Health Check
```bash
# Comprehensive health check
./scripts/database/db-health.sh
```

### Service Management
```bash
# Start database service
./scripts/service-mgmt.sh start db

# Check service status
./scripts/service-mgmt.sh status

# View logs
./scripts/service-mgmt.sh logs db
```

### Common Issues

#### Container Issues
```bash
# Check container status
docker ps | grep qldsv

# View container logs
docker logs qldsv-sqlserver

# Restart container
cd database && docker-compose restart
```

#### Connection Issues
```bash
# Test all connections
./scripts/database/db-manager.sh test-connections

# Check database status
./scripts/database/db-manager.sh status
```

#### Permission Issues
```bash
# Rebuild security completely
./scripts/database/db-manager.sh rebuild-security
```

#### Reset Environment
```bash
# Complete cleanup (removes all data!)
./scripts/service-mgmt.sh cleanup

# Restart setup
./scripts/setup/initial-setup.sh
```

## 🔮 Mở Rộng Tương Lai

### Thư Mục Đã Chuẩn Bị
- `database/06-functions/` - User-defined functions
- `database/07-procedures/` - Stored procedures
- `database/08-views/` - Views cho báo cáo
- `database/09-triggers/` - Business logic triggers

### Thêm Chức Năng Mới
1. Thêm file SQL mới vào thư mục phù hợp trong `database/`
2. Update `scripts/database/db-manager.sh` để include file mới
3. Pattern DROP + CREATE đã sẵn sàng cho tất cả scripts

## 🔐 Security & Production

### Production Checklist
- [ ] Thay đổi tất cả passwords mặc định trong `.env`
- [ ] Setup SSL certificates cho HTTPS
- [ ] Cấu hình backup schedule tự động
- [ ] Setup monitoring và logging
- [ ] Review lại security permissions
- [ ] Cấu hình reverse proxy (nginx)
- [ ] Setup environment-specific configs

### Default Passwords (PHẢI ĐỔI CHO PRODUCTION!)
- SA: `QLDSV@2024!Strong`
- PGV: `PGV@2024!`
- KHOA: `Khoa@2024!`
- APP: `App@2024!`
- SV: `123456` (theo yêu cầu đề bài)

## 📝 Notes

- Tất cả scripts đều có pattern **DROP trước CREATE** để hỗ trợ development
- Sử dụng `dev-reset` cho thay đổi thường xuyên trong development
- Sử dụng `full-reset` khi cần reset hoàn toàn
- Backup devices được tự động tạo và cấu hình
- Test data bao gồm đủ các trường hợp để test nghiệp vụ
- Database hỗ trợ Vietnamese collation cho dữ liệu tiếng Việt

---

**Status**: ✅ Production-ready với proper configuration adjustments 