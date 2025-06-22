# Bash Scripts – DevOps Helper

## 1. Giới Thiệu

Thư mục **`scripts/`** gom tập lệnh bash nhằm đơn giản hoá quá trình thiết lập và vận hành stack 3-tầng. Toàn bộ script đều có cơ chế **idempotent** (chạy nhiều lần không lỗi) và ghi log vào `backend/logs/` hoặc `frontend/logs/`.

---

## 2. Danh Sách Lệnh Chính

| Script | Chức năng | Tuỳ chọn quan trọng |
|--------|-----------|---------------------|
| `start-database.sh` | Tạo / khởi động / reset SQL Server container | `--setup` · `--reset` · `--delete` |
| `start-backend.sh`  | Tạo virtualenv + cài package + run FastAPI | `--setup` · `--reset` · `--reset-db` · `--delete` |
| `start-frontend.sh` | Cài node_modules (pnpm) + run Vite | `--setup` · `--reset` · `--delete` |

Mỗi script `start-*` đều gọi tới util tương ứng trong `scripts/utils/` để tránh trùng lặp.

---

## 3. Flow Đề Xuất

```bash
# Khởi tạo lần đầu (đơn máy mới clone repo)
./scripts/start-database.sh --setup
./scripts/start-backend.sh  --setup
./scripts/start-frontend.sh --setup

# Sau khi chỉnh .sql ➜ reset DB + reload backend
./scripts/start-backend.sh --reset-db

# Khi thay đổi dependency python
./scripts/start-backend.sh --reset

# Khi thay đổi dependency node
./scripts/start-frontend.sh --reset
```

---

## 4. Mẹo & Ghi Chú

1. **Server luôn chạy nền** – script không block terminal (log stream tới file). Muốn xem log realtime:
   ```bash
   tail -f backend/logs/server.log
   tail -f frontend/logs/server.log
   ```
2. **Port bị chiếm** khi server đang chạy là bình thường; chỉ quan tâm lỗi khác.
3. **Windows**: nên dùng Git Bash hoặc WSL2 để đảm bảo tương thích.

---

© 2024 – Nhóm QLDSV-HTC 