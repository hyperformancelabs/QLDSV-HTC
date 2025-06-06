# QLDSV-HTC Backend Documentation

Tài liệu hướng dẫn phát triển và sử dụng Backend cho hệ thống Quản lý điểm sinh viên theo hệ tín chỉ.

## Kiến trúc

Backend được xây dựng với FastAPI (Python), cung cấp RESTful API cho frontend và tương tác với SQL Server database.

## Cấu trúc thư mục

```
backend/
├── app/                   # Main application code
│   ├── api/               # API endpoints & routers
│   │   └── endpoints/     # API endpoint modules
│   ├── core/              # Core configuration
│   ├── db/                # Database models & connection
│   ├── schemas/           # Pydantic models
│   └── services/          # Business logic services
├── migrations/            # Alembic migrations
└── tests/                 # Unit and integration tests
```

## Cài đặt và chạy

```bash
# Từ thư mục project root
cd backend

# Tạo và kích hoạt môi trường ảo
python -m venv venv
source venv/bin/activate  # Linux/macOS
# hoặc
venv\Scripts\activate     # Windows

# Cài đặt dependencies
pip install -r requirements.txt

# Chạy server development
uvicorn app.main:app --reload
```

## API Documentation

Khi server đang chạy, bạn có thể truy cập API documentation tại:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Tính năng chính

1. **Authentication & Authorization**
   - JWT-based authentication
   - Role-based access control (PGV, KHOA, SV)

2. **Quản lý dữ liệu**
   - CRUD operations cho tất cả entity
   - Stored procedure integration

3. **Báo cáo**
   - Endpoints cho tất cả báo cáo theo yêu cầu

## Phát triển

### Thêm API endpoint mới

1. Tạo file mới trong `app/api/endpoints/`
2. Định nghĩa router và endpoint functions
3. Import và include router trong `app/api/api.py`

### Thêm model mới

1. Định nghĩa SQLAlchemy model trong `app/db/models/`
2. Định nghĩa Pydantic schema trong `app/schemas/`
3. Tạo service trong `app/services/` nếu cần

## Testing

```bash
# Chạy tất cả tests
pytest

# Chạy tests với coverage
pytest --cov=app
```

## Deployment

```bash
# Production server
uvicorn app.main:app --host 0.0.0.0 --port 8000

# Với Gunicorn (recommended cho production)
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker
``` 