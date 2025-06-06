# QLDSV-HTC Frontend Documentation

Tài liệu hướng dẫn phát triển và sử dụng Frontend cho hệ thống Quản lý điểm sinh viên theo hệ tín chỉ.

## Kiến trúc

Frontend được xây dựng với React và TypeScript, sử dụng Ant Design cho UI components và React Query cho data fetching.

## Cấu trúc thư mục

```
frontend/
├── public/                # Static assets
├── src/                   # Source code
│   ├── assets/            # Images, fonts, etc.
│   ├── components/        # React components
│   │   ├── common/        # Reusable components
│   │   └── specific/      # Feature-specific components
│   ├── hooks/             # Custom React hooks
│   ├── layouts/           # Page layouts
│   ├── pages/             # Page components
│   ├── services/          # API services
│   ├── store/             # State management
│   ├── styles/            # Global styles
│   ├── types/             # TypeScript types
│   └── utils/             # Utility functions
└── tests/                 # Unit and integration tests
```

## Cài đặt và chạy

```bash
# Từ thư mục project root
cd frontend

# Cài đặt dependencies
npm install

# Chạy development server
npm run dev
```

## Tính năng chính

1. **Authentication**
   - Login form cho PGV, KHOA, SV
   - Role-based routing và access control

2. **Quản lý dữ liệu**
   - Forms cho tất cả entity (Khoa, Lớp, Sinh viên, Môn học, v.v.)
   - Data validation

3. **Đăng ký lớp tín chỉ**
   - UI cho sinh viên đăng ký lớp
   - Hiển thị thông tin lớp và số lượng đăng ký

4. **Nhập điểm**
   - UI cho giảng viên nhập điểm
   - Tính toán điểm tự động

5. **Báo cáo**
   - Hiển thị và in tất cả báo cáo theo yêu cầu
   - Export to PDF/Excel

## Phát triển

### Thêm component mới

1. Tạo component trong thư mục phù hợp (`components/common/` hoặc `components/specific/`)
2. Sử dụng TypeScript interfaces cho props
3. Implement component logic và UI

### Thêm page mới

1. Tạo page component trong `pages/`
2. Thêm route trong `App.tsx` hoặc router configuration
3. Implement page logic và UI

### Kết nối với API

1. Thêm service function trong `services/`
2. Sử dụng React Query hooks để fetch data
3. Handle loading, error, và success states

## Testing

```bash
# Chạy tất cả tests
npm test

# Chạy tests với coverage
npm test -- --coverage
```

## Build cho production

```bash
# Build frontend
npm run build

# Preview built version
npm run preview
``` 