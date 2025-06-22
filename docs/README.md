# QLDSV-HTC – Hệ Thống Quản Lý Điểm Sinh Viên Theo Hệ Tín Chỉ

## 1. Giới Thiệu

QLDSV-HTC là đồ án môn **Hệ Quản Trị Cơ Sở Dữ Liệu** mô phỏng hệ thống quản lý điểm sinh viên với các vai trò **PGV (Phòng Giáo Vụ)**, **KHOA**, **GV (Giảng Viên)** và **SV (Sinh Viên)**. Dự án được triển khai theo kiến trúc **3 tầng**:

1. **Database** – SQL Server 2022 (Docker) chứa toàn bộ T-SQL (DDL/DML/Stored Procedure).
2. **Backend** – Python / FastAPI cung cấp RESTful API & bảo mật JWT/Session.
3. **Frontend** – React 18 + Vite SPA với Zustand + Tailwind CSS.

Hệ thống kèm bộ **bash scripts** để tự động hoá cài đặt, khởi chạy, reset dữ liệu và kiểm thử.

---

## 2. Cấu Trúc Thư Mục

```text
QLDSV-HTC/
├── backend/        # FastAPI – API, Logic, Service & Dependency
├── database/       # T-SQL – Scripts Tạo DB, Bảng, Index, SP, View, Data
├── frontend/       # React – SPA UI + Zustand store
├── scripts/        # Bash helpers: start-backend.sh / start-database.sh / …
├── docs/           # Tài liệu hướng dẫn (README này, ERD v.v.)
└── DESCRIPTION.md  # Đề bài chính thức của đồ án
```

Chi tiết từng tầng xem README tương ứng bên trong thư mục.

---

## 3. Công Nghệ Sử Dụng

| Tầng      | Công Nghệ Chính                       | Ghi Chú |
|-----------|---------------------------------------|---------|
| Database  | SQL Server 2022 (Docker)              | T-SQL, Stored Procedure, Function, Trigger, Index |
| Backend   | Python ≥ 3.9, FastAPI, SQLAlchemy    | Async, pyodbc, JWT, Rate-Limit, Logger |
| Frontend  | React 18, TypeScript, Vite            | Shadcn UI, React Hook Form + Zod, Zustand store |
| DevOps    | Docker Compose, Bash Script           | `./scripts` tự động hoá cài đặt & khởi chạy |

---

## 4. Yêu Cầu Hệ Thống

* **Docker** & **docker-compose** ≥ v24
* **Node.js** ≥ 18 và **pnpm** ≥ 8 (để cài gói front-end)
* **Python** ≥ 3.9 (khuyến nghị 3.11)
* macOS / Linux / Windows WSL2

---

## 5. Cài Đặt Nhanh

```bash
# 1. Clone repo
$ git clone https://github.com/<your-org>/QLDSV-HTC.git
$ cd QLDSV-HTC

# 2. Tạo file môi trường cho từng tầng
$ cp .env.example .env
$ cp backend/.env.example backend/.env
$ cp frontend/.env.example frontend/.env.local
$ cp database/.env.example database/.env

# 3. Khởi chạy toàn bộ stack (DB → BackEnd → FrontEnd)
$ ./scripts/start-database.sh --setup   # tạo container SQL Server + seed data
$ ./scripts/start-backend.sh  --setup   # cài venv, package & start FastAPI
$ ./scripts/start-frontend.sh --setup   # cài node_modules bằng pnpm & start Vite
```

Sau khi hoàn tất:

* Frontend: http://localhost:5173
* OpenAPI Docs: http://localhost:8000/docs
* Health Check: http://localhost:5173/health

---

## 6. Tài Khoản Demo

| Vai Trò | Username | Password |
|---------|----------|----------|
| PGV     | pgv_user | PGV@123456 |
| KHOA    | khoa_user| KHOA@123456 |
| GV (PGV)| GV045    | GV045pass123# |
| SV      | N21DCCN064 | 123456 |

---

## 7. Lộ Trình Phát Triển

1. **Thiết kế DB**: chỉnh sửa file `.sql` trong `database/`, sau đó `./scripts/start-backend.sh --reset-db` để áp dụng.
2. **Xây dựng API**: thêm endpoint FastAPI ➜ `./scripts/start-backend.sh` (hot-reload).
3. **Xây dựng giao diện**: `pnpm dev` hoặc `./scripts/start-frontend.sh`.
4. **Viết test & CI**: bảo đảm unit test pass trước khi merge.

---

## 8. Chuẩn Mã Nguồn

* **Python**: PEP-8 + typing đầy đủ.
* **TypeScript**: ESLint + Prettier.
* **T-SQL**: PascalCase cho tên đối tượng, snake_case cho cột.
* Nguyên tắc **Clean Code**, **DRY**, **Single Responsibility** (xem `02-terminal-commands.mdc`).

---

## 9. Giấy Phép

Mã nguồn phát hành dưới giấy phép **MIT**.

---

> © 2024 – Nhóm QLDSV-HTC – Trường Đại Học XYZ 