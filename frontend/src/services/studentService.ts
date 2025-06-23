/**
 * API service for Student management
 */

import { API_BASE_URL } from '@/lib/config';

// Basic Student data structure
export interface Student {
  MASV: string;       // Student ID
  HO: string;         // Last name
  TEN: string;        // First name
  MALOP: string;      // Class code
  PHAI: boolean;      // Gender (false=Nam, true=Nữ)
  NGAYSINH: string;   // Birthday (ISO format: YYYY-MM-DD)
  DIACHI: string;     // Address
  DANGHIHOC: boolean; // Study status
  TENLOP?: string;    // Class name (optional, from joined data)
  PASSWORD?: string;  // Password (only used when creating new students)
}

// Extended Student with metadata for UI state management
export interface StudentWithMeta extends Student {
  isNew?: boolean;       // Newly added, not yet saved
  isDeleted?: boolean;   // Marked for deletion
  isModified?: boolean;  // Modified from original data
  originalData?: Student;// For tracking original state for undo
}

// Action types for the student management stack (for undo/redo)
export type StudentAction = 
  | { type: 'ADD', student: Student }
  | { type: 'EDIT', student: Student, original: Student }
  | { type: 'DELETE', student: Student };

// Pagination response type
export interface PaginatedStudents {
  data: Student[];
  total: number;
  page: number;
  page_size: number;
}

const BASE_ENDPOINT = `${API_BASE_URL}/sinhvien`;

/**
 * Fetch students by class with pagination
 * @param malop Class code
 * @param page Page number (1-based)
 * @param pageSize Items per page
 * @param search Optional search term
 * @param sortBy Column to sort by
 * @param sortDir Sort direction
 * @returns Promise with paginated students data
 */
export async function fetchStudentsByClass(
  malop: string,
  page: number = 1, 
  pageSize: number = 50,
  search: string = '',
  sortBy: string = 'HO',
  sortDir: string = 'ASC'
): Promise<PaginatedStudents> {
  try {
    // Build query string
    const params = new URLSearchParams({
      page: page.toString(),
      page_size: pageSize.toString(),
      sort_by: sortBy,
      sort_dir: sortDir
    });
    
    if (search) {
      params.append('search', search);
    }
    
    const url = `${BASE_ENDPOINT}/class/${malop}?${params.toString()}`;
    const res = await fetch(url, { 
      credentials: 'include',
      headers: {
        'Accept': 'application/json'
      }
    });
    
    if (!res.ok) {
      const errorData = await res.json().catch(() => null);
      throw new Error(errorData?.detail || 'Không lấy được danh sách sinh viên');
    }
    
    const data = await res.json();
    return data as PaginatedStudents;
  } catch (error) {
    console.error('Error fetching students:', error);
    throw new Error('Không thể kết nối đến máy chủ');
  }
}

/**
 * Create a new student
 * @param student Student data
 */
export async function createStudent(student: Student): Promise<void> {
  try {
    console.log('Creating student:', student.MASV);
    console.log('Request payload:', JSON.stringify(student, null, 2));
    
    const res = await fetch(BASE_ENDPOINT, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      credentials: 'include',
      body: JSON.stringify(student),
    });
    
    if (!res.ok) {
      const data = await res.json().catch(() => null);
      console.log('Error response from server:', data);
      throw new Error(data?.detail || 'Thêm sinh viên thất bại');
    }
  } catch (error) {
    console.error('Error creating student:', error);
    throw error instanceof Error ? error : new Error('Lỗi không xác định khi thêm sinh viên');
  }
}

/**
 * Update an existing student
 * @param masv Student ID
 * @param student Student data
 */
export async function updateStudent(masv: string, student: Student): Promise<void> {
  try {
    console.log('Updating student:', masv);
    console.log('Request payload:', JSON.stringify(student, null, 2));
    
    const res = await fetch(`${BASE_ENDPOINT}/${masv}`, {
      method: 'PUT',
      headers: { 
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      credentials: 'include',
      body: JSON.stringify(student),
    });
    
    if (!res.ok) {
      const data = await res.json().catch(() => null);
      console.log('Error response from server:', data);
      throw new Error(data?.detail || 'Cập nhật sinh viên thất bại');
    }
  } catch (error) {
    console.error('Error updating student:', error);
    throw error instanceof Error ? error : new Error('Lỗi không xác định khi cập nhật sinh viên');
  }
}

/**
 * Delete a student by ID
 * @param masv Student ID to delete
 */
export async function deleteStudent(masv: string): Promise<void> {
  try {
    const res = await fetch(`${BASE_ENDPOINT}/${masv}`, {
      method: 'DELETE',
      credentials: 'include',
      headers: {
        'Accept': 'application/json'
      }
    });
    
    if (!res.ok) {
      const data = await res.json().catch(() => null);
      throw new Error(data?.detail || 'Xoá sinh viên thất bại');
    }
  } catch (error) {
    console.error('Error deleting student:', error);
    throw error instanceof Error ? error : new Error('Lỗi không xác định khi xóa sinh viên');
  }
}

/**
 * Validate student data before saving
 * @param student Student data to validate
 * @returns Error message if invalid, null if valid
 */
export function validateStudent(student: Student): string | null {
  if (!student.MASV?.trim()) return 'Mã sinh viên không được để trống';
  if (student.MASV.trim().length > 10) return 'Mã sinh viên không được vượt quá 10 ký tự';
  
  if (!student.HO?.trim()) return 'Họ sinh viên không được để trống';
  if (student.HO.trim().length > 50) return 'Họ sinh viên không được vượt quá 50 ký tự';
  
  if (!student.TEN?.trim()) return 'Tên sinh viên không được để trống';
  if (student.TEN.trim().length > 10) return 'Tên sinh viên không được vượt quá 10 ký tự';
  
  if (!student.MALOP?.trim()) return 'Mã lớp không được để trống';
  
  if (student.PHAI === undefined || student.PHAI === null) return 'Phái không được để trống';
  
  if (!student.NGAYSINH) return 'Ngày sinh không được để trống';
  
  if (!student.DIACHI?.trim()) return 'Địa chỉ không được để trống';
  if (student.DIACHI.trim().length > 100) return 'Địa chỉ không được vượt quá 100 ký tự';
  
  // Check date format
  const datePattern = /^\d{4}-\d{2}-\d{2}$/;
  if (!datePattern.test(student.NGAYSINH)) {
    return 'Ngày sinh phải có định dạng YYYY-MM-DD';
  }
  
  // Check that birth date is at most current date minus 15 years
  const birthDate = new Date(student.NGAYSINH);
  const minBirthDate = new Date();
  minBirthDate.setFullYear(minBirthDate.getFullYear() - 15);
  
  if (birthDate > minBirthDate) {
    return 'Ngày sinh phải cách đây ít nhất 15 năm';
  }
  
  return null; // Valid if we get here
}

/**
 * Check if student ID already exists
 * @param masv Student ID to check
 * @param malop Class code (to narrow down the search)
 * @returns Boolean indicating whether student ID exists
 */
export async function checkStudentExists(masv: string, malop: string): Promise<boolean> {
  try {
    if (!masv.trim()) return false;
    
    // Fetch the first page to check if student exists
    const result = await fetchStudentsByClass(malop, 1, 10, masv);
    return result.data.some(s => s.MASV === masv);
  } catch {
    return false; // In case of error, don't block the user
  }
} 