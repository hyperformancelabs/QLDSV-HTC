# Frontend – React 18 + Vite

## 1. Giới Thiệu

Thư mục **`frontend/`** chứa mã nguồn giao diện người dùng cho QLDSV-HTC. Ứng dụng là SPA (Single-Page-Application) được xây dựng bằng **React 18** và **TypeScript**, sử dụng **Tailwind CSS** + **Shadcn UI** để đảm bảo UI thống nhất và hiện đại.

---

## 2. Công Nghệ & Thư Viện Chính

* **React 18** – JSX + hooks
* **Vite** – Dev Server & Bundler siêu nhanh
* **TypeScript** – Kiểu hoá chặt chẽ
* **Zustand** – Quản lý trạng thái (AuthStore, …)
* **React Hook Form** + **Zod** – Form & validation
* **Shadcn/UI** – Component library (Radix + Tailwind)
* **Lucide-react** – Bộ icon
* **@tanstack/react-query** (dự kiến) – Fetch & cache API

---

## 3. Cấu Trúc Thư Mục

```text
frontend/
├── public/             # Tài nguyên tĩnh (favicon…)
├── src/
│   ├── components/     # Thành phần UI dùng lại được
│   │   └── ui/         # Các base component của Shadcn
│   ├── hooks/          # Custom React hook
│   ├── layouts/        # Layout (MainLayout, Header, Sidebar)
│   ├── pages/          # Route components (login, dashboard, …)
│   ├── services/       # Gọi API (authService, …)
│   ├── store/          # Zustand stores
│   ├── styles/         # Tailwind global CSS
│   ├── types/          # Định nghĩa TypeScript chung
│   └── main.tsx        # Điểm vào ứng dụng
├── tailwind.config.js  # Cấu hình Tailwind (theming bằng CSS variable)
└── vite.config.ts      # Cấu hình Vite + alias @ -> src/
```

---

## 4. Thiết Lập

```bash
# Cài đặt dependencies (dùng pnpm thay vì npm/yarn)
$ cd frontend
$ pnpm install

# (tuỳ chọn) Thiết lập biến môi trường
$ cp .env.example .env.local
```

> **Lưu ý**: Toàn bộ hướng dẫn, script và CI đều giả định dùng **pnpm**. Nếu buộc phải dùng `npm` vui lòng tự chịu trách nhiệm về khác biệt.

---

## 5. Khởi Chạy

```bash
# Dev mode (HMR ở cổng 5173, cấu hình trong .env.local)
$ pnpm dev

# Build production
$ pnpm build

# Xem thử build production
$ pnpm preview
```

Sau khi server chạy thành công:

* Trang chủ: http://localhost:5173
* Health check: http://localhost:5173/health

---

## 6. Quy Ước Mã Nguồn

* **SCSS/Tailwind**: Không inline style; tuỳ chỉnh theme qua CSS variable.
* **Component**: Nếu phức tạp, tách nhỏ vào `components/<feature>/`.
* **Hooks**: Đặt trong `src/hooks` với prefix `use`.
* **Route**: Khai báo ở `src/App.tsx`, hạn chế lồng quá 2 cấp.

---

## 7. Kiểm Thử & QA

* ESLint: `pnpm lint`
* Unit test: (đang WIP) – dự kiến dùng Vitest + @testing-library/react.

---

## 8. Tài Khoản Demo

Xem bảng trong [`docs/README.md`](../docs/README.md).

---

© 2024 – Nhóm QLDSV-HTC 