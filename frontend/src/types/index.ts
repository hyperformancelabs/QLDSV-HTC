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
  danghihoc: boolean;
  tenlop?: string;
  password?: string;
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

// Lecturer Account types
export interface LecturerAccount {
  MAGV: string;
  HO: string;
  TEN: string;
  HOCVI: string | null;
  HOCHAM: string | null;
  CHUYENMON: string | null;
  MAKHOA: string;
  TENKHOA: string;
  HasLogin: boolean;
  RoleName: string | null;
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

// LopTinChi types (enhanced Credit Class)
export interface LopTinChi {
  MALTC: number;
  NIENKHOA: string;
  HOCKY: number;
  MAMH: string;
  TENMH: string;
  NHOM: number;
  MAGV: string;
  HOTENGV: string;
  MAKHOA: string;
  TENKHOA: string;
  SOSVTOITHIEU: number;
  SOSVDANGKY: number;
  HUYLOP: boolean;
}

// LopTinChi Filter types
export interface LopTinChiFilter {
  nienkhoa?: string;
  hocky?: number;
  makhoa?: string;
  only_available?: boolean;
}

// LopTinChi Create/Update types
export interface LopTinChiUpsert {
  MALTC?: number;
  NIENKHOA: string;
  HOCKY: number;
  MAMH: string;
  NHOM: number;
  MAGV: string;
  MAKHOA: string;
  SOSVTOITHIEU: number;
}

// DangKy types (enhanced Registration)
export interface DangKy {
  MALTC: number;
  NIENKHOA: string;
  HOCKY: number;
  TENMH: string;
  NHOM: number;
  HOTENGV: string;
  DIEM_CC: number | null;
  DIEM_GK: number | null;
  DIEM_CK: number | null;
  DIEM_HET_MON: number | null;
  HUYDANGKY: boolean;
}

// DangKy Create/Cancel types
export interface DangKyCreate {
  MALTC: number;
  MASV: string;
}

export interface DangKyCancel {
  MALTC: number;
  MASV: string;
}

// Student Info type
export interface StudentInfo {
  MASV: string;
  HO: string;
  TEN: string;
  MALOP: string;
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