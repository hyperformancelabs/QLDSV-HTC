// User types
export enum UserRole {
  PGV = "PGV",
  KHOA = "KHOA",
  SV = "SV"
}

export interface User {
  id: string;
  username: string;
  ho: string;
  ten: string;
  role: UserRole;
  masv?: string;
  magv?: string;
  malop?: string;
  makhoa?: string;
}

// Faculty types
export interface Faculty {
  makhoa: string;
  tenkhoa: string;
}

// Class types
export interface Class {
  malop: string;
  tenlop: string;
  khoahoc: string;
  makhoa: string;
}

// Student types
export interface Student {
  masv: string;
  ho: string;
  ten: string;
  malop: string;
  phai: boolean;
  ngaysinh: string;
  diachi: string;
  dangnghihoc: boolean;
}

// Subject types
export interface Subject {
  mamh: string;
  tenmh: string;
  sotiet_lt: number;
  sotiet_th: number;
}

// Teacher types
export interface Teacher {
  magv: string;
  ho: string;
  ten: string;
  makhoa: string;
  hocvi?: string;
  hocham?: string;
  chuyenmon?: string;
}

// Credit Class types
export interface CreditClass {
  maltc: string;
  nienkhoa: string;
  hocky: number;
  mamh: string;
  tenmh?: string;
  nhom: number;
  magv: string;
  tengv?: string;
  makhoa: string;
  sosvtoithieu: number;
  huylop: boolean;
}

// Registration types
export interface Registration {
  maltc: string;
  masv: string;
  diem_cc?: number | null;
  diem_gk?: number | null;
  diem_ck?: number | null;
  huy_dang_ky: boolean;
}

// Grade Report types
export interface GradeReport {
  maltc: string;
  mamh: string;
  tenmh: string;
  nienkhoa: string;
  hocky: number;
  nhom: number;
  diem_cc?: number | null;
  diem_gk?: number | null;
  diem_ck?: number | null;
  diem_tk?: number | null;
}

// Tuition Fee types
export interface TuitionFee {
  masv: string;
  nienkhoa: string;
  hocky: number;
  hocphi: number;
  paid: boolean;
}

// Health Check types
export interface HealthCheckResponse {
  status: "healthy" | "warning" | "unhealthy";
  timestamp: string;
  version: string;
  services: {
    api: {
      status: "up" | "down";
      responseTime: number;
    };
    database: {
      status: "up" | "down";
      version?: string;
      error?: string;
    };
  };
}

// API Response types
export interface ApiResponse<T> {
  status: string;
  data: T;
  message?: string;
}

export interface ApiError {
  status: string;
  message: string;
  details?: any;
}

// Pagination types
export interface PaginationParams {
  page: number;
  limit: number;
  search?: string;
  sortBy?: string;
  sortOrder?: "asc" | "desc";
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  };
}

// Filter types
export interface FilterOption {
  label: string;
  value: string;
}

export interface FilterParams {
  [key: string]: string | number | boolean | undefined;
} 