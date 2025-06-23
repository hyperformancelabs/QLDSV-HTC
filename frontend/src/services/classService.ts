/**
 * API service for Class management
 */

import { API_BASE_URL } from '@/lib/config';

// Basic Class data structure
export interface Class {
  MALOP: string;     // Class code
  TENLOP: string;    // Class name
  KHOAHOC: string;   // Academic years (e.g., "2021-2025")
  MAKHOA: string;    // Faculty code
  TENKHOA?: string;  // Faculty name
  SOSINHVIEN?: number;// Student count (optional)
}

// Extended Class with metadata for UI state management
export interface ClassWithMeta extends Class {
  isNew?: boolean;      // Newly added, not yet saved
  isDeleted?: boolean;  // Marked for deletion
  isModified?: boolean; // Modified from original data
  originalData?: Class; // For tracking original state for undo
}

// Action types for the class management stack (for undo/redo)
export type ClassAction = 
  | { type: 'ADD', class: Class }
  | { type: 'EDIT', class: Class, original: Class }
  | { type: 'DELETE', class: Class };

// Filter structure for class listing
export interface ClassFilters {
  makhoa?: string;  // Faculty code filter
  khoahoc?: string; // Academic year filter
}

const BASE_ENDPOINT = `${API_BASE_URL}/lop`;

/**
 * Fetch all classes or filtered classes from API
 * @param filters Optional filters for makhoa and khoahoc
 * @returns Promise with array of classes
 */
export async function fetchClasses(filters?: ClassFilters): Promise<Class[]> {
  try {
    // Build query parameters from filters
    const params = new URLSearchParams();
    if (filters?.makhoa) params.append('makhoa', filters.makhoa);
    if (filters?.khoahoc) params.append('khoahoc', filters.khoahoc);
    
    const queryString = params.toString() ? `?${params.toString()}` : '';
    const res = await fetch(`${BASE_ENDPOINT}${queryString}`, { 
      credentials: 'include',
      headers: {
        'Accept': 'application/json'
      }
    });
    
    if (!res.ok) {
      const errorData = await res.json().catch(() => null);
      throw new Error(errorData?.detail || 'Không lấy được danh sách lớp');
    }
    
    const data = await res.json();
    return data.data as Class[];
  } catch (error) {
    console.error('Error fetching classes:', error);
    throw new Error('Không thể kết nối đến máy chủ');
  }
}

/**
 * Check if a class has students
 * @param malop Class code to check
 * @returns Number of students in the class
 */
export async function checkClassHasStudents(malop: string): Promise<number> {
  try {
    const res = await fetch(`${BASE_ENDPOINT}/${malop}/student-count`, {
      credentials: 'include',
      headers: {
        'Accept': 'application/json'
      }
    });

    if (!res.ok) {
      const errorData = await res.json().catch(() => null);
      throw new Error(errorData?.detail || 'Không kiểm tra được số sinh viên');
    }

    const data = await res.json();
    return data.student_count as number;
  } catch (error) {
    console.error('Error checking class student count:', error);
    throw new Error('Không thể kiểm tra số sinh viên trong lớp');
  }
}

/**
 * Create or update a class
 * @param cls - Class data to save
 */
export async function upsertClass(cls: Class): Promise<void> {
  try {
    console.log('Making upsert request for class:', cls.MALOP, 'with data:', cls);
    
    const res = await fetch(BASE_ENDPOINT, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      credentials: 'include',
      body: JSON.stringify(cls),
    });
    
    console.log('Upsert response status:', res.status);
    
    if (!res.ok) {
      const data = await res.json().catch(() => null);
      console.error('Upsert error response:', data);
      throw new Error(data?.detail || 'Lưu lớp thất bại');
    }
    
    console.log('Upsert successful for', cls.MALOP);
  } catch (error) {
    console.error('Error in upsertClass:', error);
    throw error instanceof Error ? error : new Error('Lỗi không xác định khi lưu lớp');
  }
}

/**
 * Delete a class by code
 * @param malop - Class code to delete
 */
export async function deleteClass(malop: string): Promise<void> {
  try {
    const res = await fetch(`${BASE_ENDPOINT}/${malop}`, {
      method: 'DELETE',
      credentials: 'include',
      headers: {
        'Accept': 'application/json'
      }
    });
    
    if (!res.ok) {
      const data = await res.json().catch(() => null);
      throw new Error(data?.detail || 'Xoá lớp thất bại');
    }
  } catch (error) {
    console.error('Error deleting class:', error);
    throw error instanceof Error ? error : new Error('Lỗi không xác định khi xóa lớp');
  }
}

/**
 * Process multiple class updates in sequence
 * @param classes - Array of classes to create/update
 */
export async function bulkUpsertClasses(classes: Class[]): Promise<void> {
  console.log('bulkUpsertClasses called with', classes.length, 'classes');
  
  // We'll process them in sequence to maintain consistency
  for (const cls of classes) {
    try {
      console.log('Upserting class:', cls.MALOP);
      await upsertClass(cls);
      console.log('Upsert successful for:', cls.MALOP);
    } catch (error) {
      console.error('Error upserting class', cls.MALOP, ':', error);
      throw error; // Re-throw to handle in the calling function
    }
  }
}

/**
 * Validate class data before saving
 * @param cls - Class data to validate
 * @param isNew - Boolean indicating whether the class is new
 * @returns Error message if invalid, null if valid
 */
export function validateClass(cls: Class, isNew: boolean = false): string | null {
  if (!cls.MALOP.trim()) return 'Mã lớp không được để trống';
  if (cls.MALOP.trim().length > 10) return 'Mã lớp không được vượt quá 10 ký tự';
  
  if (!cls.TENLOP.trim()) return 'Tên lớp không được để trống';
  if (cls.TENLOP.trim().length > 50) return 'Tên lớp không được vượt quá 50 ký tự';
  
  if (!cls.KHOAHOC.trim()) return 'Niên khóa không được để trống';
  
  // Validate pattern "YYYY-YYYY"
  const khoahocPattern = /^(\d{4})-(\d{4})$/;
  if (!khoahocPattern.test(cls.KHOAHOC.trim())) {
    return 'Niên khóa phải theo định dạng YYYY-YYYY';
  }

  const [, startStr, endStr] = cls.KHOAHOC.match(khoahocPattern) as RegExpMatchArray;
  const startYear = Number(startStr);
  const endYear = Number(endStr);
  const currentYear = new Date().getFullYear();

  if (isNew) {
    if (startYear < currentYear || startYear > currentYear + 3) {
      return `Năm bắt đầu phải từ ${currentYear} đến ${currentYear + 3}`;
    }
  }

  if (endYear < startYear) {
    return 'Năm kết thúc phải lớn hơn hoặc bằng năm bắt đầu';
  }

  if (endYear - startYear > 7) {
    return 'Khoảng cách tối đa giữa năm bắt đầu và năm kết thúc là 7 năm';
  }

  if (endYear > currentYear + 10) {
    return `Năm kết thúc không được vượt quá ${currentYear + 10}`;
  }
  
  if (!cls.MAKHOA.trim()) return 'Mã khoa không được để trống';
  if (cls.MAKHOA.trim().length > 10) return 'Mã khoa không được vượt quá 10 ký tự';
  
  return null; // Valid if we get here
}

/**
 * Check if class code already exists (for new classes)
 * @param malop - Class code to check
 * @returns Boolean indicating whether code exists
 */
export async function checkClassCodeExists(malop: string): Promise<boolean> {
  try {
    if (!malop.trim()) return false;
    
    const classes = await fetchClasses();
    return classes.some(c => c.MALOP === malop);
  } catch {
    return false; // In case of error, don't block the user
  }
}

/**
 * Check if class name already exists (for new classes)
 * @param tenlop - Class name to check
 * @returns Boolean indicating whether name exists
 */
export async function checkClassNameExists(tenlop: string): Promise<boolean> {
  try {
    if (!tenlop.trim()) return false;
    
    const classes = await fetchClasses();
    return classes.some(c => c.TENLOP === tenlop);
  } catch {
    return false; // In case of error, don't block the user
  }
} 