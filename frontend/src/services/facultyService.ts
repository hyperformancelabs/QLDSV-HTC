/**
 * API service for Faculty management
 */

import { API_BASE_URL } from '@/lib/config';

// Basic Faculty data structure
export interface Faculty {
  // DB-style keys (primary)
  MAKHOA: string;      // Faculty code
  TENKHOA: string;     // Faculty name

  // camelCase aliases
  makhoa: string;
  tenkhoa: string;
}

const BASE_ENDPOINT = `${API_BASE_URL}/khoa`;

/**
 * Fetch all faculties from API
 * @returns Promise with array of faculties
 */
export async function fetchFaculties(): Promise<Faculty[]> {
  try {
    const res = await fetch(`${BASE_ENDPOINT}`, { 
      credentials: 'include',
      headers: {
        'Accept': 'application/json'
      }
    });
    
    if (!res.ok) {
      const errorData = await res.json().catch(() => null);
      throw new Error(errorData?.detail || 'Không lấy được danh sách khoa');
    }
    
    const data = await res.json();
    // Normalize and include both DB-style and camelCase keys
    return (data.data as any[]).map((item) => {
      const code = (item.MAKHOA ?? item.makhoa).trim();
      const name = item.TENKHOA ?? item.tenkhoa;

      return {
        MAKHOA: code,
        TENKHOA: name,
        makhoa: code,
        tenkhoa: name,
      } as Faculty;
    });
  } catch (error) {
    console.error('Error fetching faculties:', error);
    throw new Error('Không thể kết nối đến máy chủ');
  }
}

export { fetchFaculties as getAllFaculties }; 