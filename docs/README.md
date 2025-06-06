# QLDSV-HTC: Hệ thống quản lý điểm sinh viên theo hệ tín chỉ

Đây là hệ thống quản lý điểm sinh viên theo hệ tín chỉ, được phát triển cho môn học "Hệ quản trị Cơ sở Dữ liệu". Hệ thống bao gồm các chức năng quản lý lớp học, sinh viên, môn học, lớp tín chỉ, đăng ký học phần và quản lý điểm.

## Kiến trúc hệ thống

Hệ thống được xây dựng với kiến trúc 3 tầng:

1. **Database Layer**: SQL Server - stored procedures, functions, views, triggers
2. **Backend Layer**: FastAPI (Python) - RESTful API, business logic
3. **Frontend Layer**: React (TypeScript) - Giao diện người dùng

## Yêu cầu hệ thống

- Docker và Docker Compose
- Git
- Python 3.9+ (cho phát triển backend)
- Node.js 16+ (cho phát triển frontend)

## Cài đặt và chạy

### 1. Clone repository

```bash
git clone https://github.com/yourusername/QLDSV-HTC.git
cd QLDSV-HTC
```

### 2. Thiết lập môi trường

Sao chép file môi trường mẫu và điều chỉnh nếu cần:

```bash
cp .env.example .env
```

### 3. Thiết lập và chạy hệ thống

```bash
# Thiết lập database
./scripts/setup/db/setup-database.sh

# Thiết lập backend
./scripts/setup/be/setup-backend.sh

# Thiết lập frontend
./scripts/setup/fe/setup-frontend.sh
```

## Tài liệu chi tiết

Để biết thêm thông tin chi tiết, vui lòng tham khảo các tài liệu sau:

- [Đề bài chi tiết](DESCRIPTION.md)
- [Tài liệu database](docs/DATABASE.md)
- [Tài liệu backend](docs/BACKEND.md)
- [Tài liệu frontend](docs/FRONTEND.md)

## Phân quyền

Hệ thống có 3 nhóm người dùng chính:

1. **PGV (Phòng Giáo Vụ)**: Có toàn quyền trên hệ thống
2. **Khoa**: Quản lý điểm của sinh viên thuộc khoa
3. **SV (Sinh Viên)**: Đăng ký lớp tín chỉ, xem điểm

## Giấy phép

Xem file [LICENSE](LICENSE) để biết thêm chi tiết.
