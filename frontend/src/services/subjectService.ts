/**
 * API service for Subject management
 */

import { API_BASE_URL } from '@/lib/config';

// Basic Subject data structure
export interface Subject {
  // Primary DB-style keys
  MAMH: string;          // Subject code (primary)
  TENMH: string;         // Subject name
  SOTIET_LT: number;     // Theory hours
  SOTIET_TH: number;     // Practice hours
  IS_LINKED: boolean;    // Whether this subject is used by any credit classes

  // Camel-case aliases for convenience
  mamh: string;
  tenmh: string;
  sotiet_lt: number;
  sotiet_th: number;
}

// Extended Subject with metadata for UI state management
export interface SubjectWithMeta extends Subject {
  isNew?: boolean;      // Newly added, not yet saved
  isDeleted?: boolean;  // Marked for deletion
  isModified?: boolean; // Modified from original data
  originalData?: Subject; // For tracking original state for undo
}

// Action types for the subject management stack (for undo/redo)
export type SubjectAction = 
  | { type: 'ADD', subject: Subject }
  | { type: 'EDIT', subject: Subject, original: Subject }
  | { type: 'DELETE', subject: Subject };

const BASE_ENDPOINT = `${API_BASE_URL}/monhoc`;

/**
 * Fetch all subjects from API
 * @returns Promise with array of subjects
 */
export async function fetchSubjects(): Promise<Subject[]> {
  try {
    const res = await fetch(BASE_ENDPOINT, { 
      credentials: 'include',
      headers: {
        'Accept': 'application/json'
      }
    });
    
    if (!res.ok) {
      const errorData = await res.json().catch(() => null);
      throw new Error(errorData?.detail || 'Không lấy được danh sách môn học');
    }
    
    const data = await res.json();
    // Normalize keys and include both DB-style (uppercase) and camelCase versions
    return (data.data as any[]).map((item) => {
      const code = (item.MAMH ?? item.mamh).trim();
      const name = item.TENMH ?? item.tenmh;
      const theory = item.SOTIET_LT ?? item.sotiet_lt ?? 0;
      const practice = item.SOTIET_TH ?? item.sotiet_th ?? 0;
      const linked = item.IS_LINKED ?? item.is_linked ?? false;

      return {
        // DB-style keys
        MAMH: code,
        TENMH: name,
        SOTIET_LT: theory,
        SOTIET_TH: practice,
        IS_LINKED: linked,

        // camelCase aliases
        mamh: code,
        tenmh: name,
        sotiet_lt: theory,
        sotiet_th: practice,
      } as Subject;
    });
  } catch (error) {
    console.error('Error fetching subjects:', error);
    throw new Error('Không thể kết nối đến máy chủ');
  }
}

/**
 * Create or update a subject
 * @param sub - Subject data to save
 */
export async function upsertSubject(sub: Subject): Promise<void> {
  try {
    console.log('Making upsert request for subject:', sub.MAMH, 'with data:', sub);
    
    const res = await fetch(BASE_ENDPOINT, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      credentials: 'include',
      body: JSON.stringify(sub),
    });
    
    console.log('Upsert response status:', res.status);
    
    if (!res.ok) {
      const data = await res.json().catch(() => null);
      console.error('Upsert error response:', data);
      throw new Error(data?.detail || 'Lưu môn học thất bại');
    }
    
    console.log('Upsert successful for', sub.MAMH);
  } catch (error) {
    console.error('Error in upsertSubject:', error);
    throw error instanceof Error ? error : new Error('Lỗi không xác định khi lưu môn học');
  }
}

/**
 * Delete a subject by code
 * @param mamh - Subject code to delete
 */
export async function deleteSubject(mamh: string): Promise<void> {
  try {
    const res = await fetch(`${BASE_ENDPOINT}/${mamh}`, {
      method: 'DELETE',
      credentials: 'include',
      headers: {
        'Accept': 'application/json'
      }
    });
    
    if (!res.ok) {
      const data = await res.json().catch(() => null);
      throw new Error(data?.detail || 'Xoá môn học thất bại');
    }
  } catch (error) {
    console.error('Error deleting subject:', error);
    throw error instanceof Error ? error : new Error('Lỗi không xác định khi xóa môn học');
  }
}

/**
 * Process multiple subject updates in sequence
 * @param subjects - Array of subjects to create/update
 */
export async function bulkUpsertSubjects(subjects: Subject[]): Promise<void> {
  console.log('bulkUpsertSubjects called with', subjects.length, 'subjects');
  
  // We'll process them in sequence to maintain consistency
  for (const subject of subjects) {
    try {
      console.log('Upserting subject:', subject.MAMH);
      await upsertSubject(subject);
      console.log('Upsert successful for:', subject.MAMH);
    } catch (error) {
      console.error('Error upserting subject', subject.MAMH, ':', error);
      throw error; // Re-throw to handle in the calling function
    }
  }
}

/**
 * Validate subject data before saving
 * @param subject - Subject data to validate
 * @returns Error message if invalid, null if valid
 */
export function validateSubject(subject: Subject): string | null {
  if (!subject.MAMH.trim()) return 'Mã môn học không được để trống';
  if (subject.MAMH.trim().length > 10) return 'Mã môn học không được vượt quá 10 ký tự';
  
  if (!subject.TENMH.trim()) return 'Tên môn học không được để trống';
  if (subject.TENMH.trim().length > 50) return 'Tên môn học không được vượt quá 50 ký tự';
  
  if (subject.SOTIET_LT < 0) return 'Số tiết lý thuyết không được âm';
  if (subject.SOTIET_TH < 0) return 'Số tiết thực hành không được âm';
  
  const totalHours = subject.SOTIET_LT + subject.SOTIET_TH;
  if (totalHours <= 0) return 'Tổng số tiết phải lớn hơn 0';
  
  return null; // Valid if we get here
}

/**
 * Check if subject code already exists (for new subjects)
 * @param mamh - Subject code to check
 * @returns Boolean indicating whether code exists
 */
export async function checkSubjectCodeExists(mamh: string): Promise<boolean> {
  try {
    if (!mamh.trim()) return false;
    
    const subjects = await fetchSubjects();
    return subjects.some(s => s.MAMH === mamh);
  } catch {
    return false; // In case of error, don't block the user
  }
}

/**
 * Check if subject name already exists (for new subjects)
 * @param tenmh - Subject name to check
 * @returns Boolean indicating whether name exists
 */
export async function checkSubjectNameExists(tenmh: string): Promise<boolean> {
  try {
    if (!tenmh.trim()) return false;
    
    const subjects = await fetchSubjects();
    return subjects.some(s => s.TENMH === tenmh);
  } catch {
    return false; // In case of error, don't block the user
  }
}

export { fetchSubjects as getAllSubjects }; 