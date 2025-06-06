# QLDSV-HTC


<div align="center">
  <h3>Hệ thống quản lý điểm sinh viên theo hệ tín chỉ</h3>
  <p>Đồ án cuối kì môn Hệ quản trị Cơ sở Dữ liệu (HQT CSDL | RDBMS | MSSQL | SQL Server) PTIT - Đề tài Quản lý sinh viên hệ tín chỉ (QLSV HTC)</p>
</div>

## 📝 Tổng Quan

QLDSV-HTC là hệ thống quản lý điểm sinh viên theo hệ tín chỉ, được phát triển dựa trên yêu cầu đồ án môn học Hệ Quản Trị CSDL. Dự án này tập trung vào việc áp dụng các nguyên tắc và kỹ thuật quản trị cơ sở dữ liệu Microsoft SQL Server, kết hợp với kiến trúc ứng dụng hiện đại sử dụng FastAPI và React.

### Chức Năng Chính

- **Quản lý dữ liệu** khoa, lớp, sinh viên, môn học và điểm thi
- **Phân quyền người dùng** (PGV, KHOA, SV) với các chức năng riêng biệt
- **Hệ thống báo cáo** đa dạng (danh sách lớp, điểm thi, phiếu điểm)
- **Quản trị hệ thống** bao gồm sao lưu, phục hồi dữ liệu

## 🏗️ Kiến Trúc Hệ Thống

QLDSV-HTC sử dụng kiến trúc 3 lớp hiện đại:

- **Database Layer**: SQL Server (containerized) - Lưu trữ dữ liệu, stored procedures, functions
- **Backend Layer**: FastAPI (Python) - RESTful API, business logic
- **Frontend Layer**: React (TypeScript) - Giao diện người dùng

### Tech Stack

- **Database**: Microsoft SQL Server 2022
- **Backend**: FastAPI (Python 3.11+)
- **Frontend**: React + TypeScript + Vite
- **Container**: Docker & Docker Compose
- **Documentation**: OpenAPI (Swagger)

## 🚀 Bắt Đầu

### Yêu Cầu Hệ Thống

- Docker & Docker Compose
- Python 3.11+
- Node.js 18+

### Cài Đặt & Khởi Động

```bash
# Clone repository
git clone https://github.com/hyperformancelabs/QLDSV-HTC.git
cd QLDSV-HTC

# Sao chép file môi trường
cp .env.example .env

# Setup và khởi động
./scripts/setup/initial-setup.sh
./scripts/service-mgmt.sh start-all
```

Sau khi khởi động, truy cập:
- **Frontend**: http://localhost:5173
- **API Documentation**: http://localhost:8000/docs

## 💾 Cơ Sở Dữ Liệu

### Mô Hình Dữ Liệu

QLDSV-HTC sử dụng mô hình dữ liệu theo yêu cầu đề bài, gồm các bảng chính:
- **KHOA**: Quản lý thông tin khoa
- **LOP**: Quản lý thông tin lớp
- **SINHVIEN**: Quản lý thông tin sinh viên
- **MONHOC**: Quản lý thông tin môn học
- **GIANGVIEN**: Quản lý thông tin giảng viên
- **LOPTINCHI**: Quản lý thông tin lớp tín chỉ
- **DANGKY**: Quản lý thông tin đăng ký học

Chi tiết về cấu trúc database và các thao tác quản lý xem tại [Database Setup Guide](docs/DATABASE_SETUP.md).

## 👥 Hệ Thống Phân Quyền

QLDSV-HTC triển khai phân quyền theo yêu cầu đề bài với 3 nhóm người dùng:

| Nhóm | Quyền hạn | Chức năng |
|------|-----------|-----------|
| **PGV** | Toàn quyền | Tất cả chức năng |
| **KHOA** | Hạn chế | Quản lý điểm, báo cáo khoa |
| **SV** | Giới hạn | Đăng ký lớp, xem điểm |

## 📊 Báo Cáo & In Ấn

Hệ thống cung cấp các báo cáo theo yêu cầu đề bài:

1. **Danh sách lớp tín chỉ**
2. **Danh sách sinh viên đăng ký lớp tín chỉ**
3. **Bảng điểm môn học của 1 lớp tín chỉ**
4. **Phiếu điểm sinh viên**
5. **Danh sách đóng học phí của lớp**
6. **Bảng điểm tổng kết**

## 🛠️ Phát Triển

### Cấu Trúc Dự Án

```
QLDSV-HTC/
├── backend/                   # FastAPI backend
│   ├── app/                   # Main application code
│   │   ├── api/               # API endpoints & routers
│   │   │   └── endpoints/     # API endpoint modules
│   │   ├── core/              # Core configuration
│   │   ├── db/                # Database models & connection
│   │   ├── schemas/           # Pydantic models
│   │   └── services/          # Business logic services
│
├── database/                  # SQL Server database
│   ├── 01-foundation/         # Database creation & logins
│   ├── 02-schema/             # Tables & indexes
│   ├── 03-security/           # Roles & permissions
│   ├── 04-backup/             # Backup configuration
│   ├── 05-data/               # Seed data
│   ├── 06-functions/          # User-defined functions
│   ├── 07-procedures/         # Stored procedures
│   ├── 08-views/              # Database views
│   ├── 09-triggers/           # Database triggers
│   └── backups/               # Backup files
│
├── docs/                      # Project documentation
│   ├── DATABASE_SETUP.md      # Database setup guide
│   └── API_DOCS.md            # API documentation
│
├── frontend/                  # React frontend
│   ├── public/                # Static assets
│   ├── src/                   # Source code
│   │   ├── assets/            # Images, fonts, etc.
│   │   ├── components/        # React components
│   │   │   ├── common/        # Reusable components
│   │   │   └── specific/      # Feature-specific components
│   │   ├── hooks/             # Custom React hooks
│   │   ├── layouts/           # Page layouts
│   │   ├── pages/             # Page components
│   │   ├── services/          # API services
│   │   ├── store/             # State management
│   │   ├── styles/            # Global styles
│   │   ├── types/             # TypeScript types
│   │   └── utils/             # Utility functions
│
├── scripts/                   # Management scripts
│   ├── database/              # Database management scripts
│   ├── setup/                 # Setup scripts
│   └── utils/                 # Utility scripts
│
├── course_materials/          # Tài liệu môn học
│   ├── md_format/             # Giáo trình format markdown
│   └── docx_format/           # Giáo trình format Word
│
├── .env                       # Environment variables
├── .env.example               # Environment variables template
├── docker-compose.yml         # Docker Compose configuration
├── DESCRIPTION.md             # Đề bài chi tiết
├── requirements.txt           # Python dependencies
├── pyproject.toml             # Python project configuration
└── README.md                  # Project overview
```

### Quy Trình Phát Triển

1. **Database**: Xem hướng dẫn chi tiết tại [Database Setup Guide](docs/DATABASE_SETUP.md)
2. **Backend**: 
   ```bash
   cd backend
   source venv/bin/activate
   uvicorn app.main:app --reload
   ```
3. **Frontend**:
   ```bash
   cd frontend
   npm install
   npm run dev
   ```

### Đảm Bảo Chất Lượng

- **Tối ưu truy vấn**: Áp dụng các nguyên tắc từ giáo trình môn học
- **Logging**: Ghi log đầy đủ các thao tác nghiệp vụ
- **Error handling**: Xử lý lỗi rõ ràng, đầy đủ thông tin
- **Testing**: Unit test cho các nghiệp vụ quan trọng

## 📚 Tài Liệu

- [Đề bài chi tiết](DESCRIPTION.md)
- [Giáo trình](course_materials/md_format)
- [Database Setup Guide](docs/DATABASE_SETUP.md)
- [API Documentation](http://localhost:8000/docs) (khi server đang chạy)

## 📝 Ghi Chú Quan Trọng

- **Cross-Platform**: Dự án được thiết kế để chạy trên mọi nền tảng thông qua Docker
- **Tính Năng RDBMS**: Sử dụng đầy đủ Stored Procedures, Functions, Views, Triggers
- **Sao Lưu & Phục Hồi**: Triển khai đầy đủ theo yêu cầu môn học

## 📄 Giấy Phép

Copyright © 2024. All rights reserved.
