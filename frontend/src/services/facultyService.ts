/**
 * API service for Faculty management
 */

import { API_BASE_URL } from '@/lib/config';

// Basic Faculty data structure
export interface Faculty {
  MAKHOA: string;      // Faculty code
  TENKHOA: string;     // Faculty name
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
    return data.data as Faculty[];
  } catch (error) {
    console.error('Error fetching faculties:', error);
    throw new Error('Không thể kết nối đến máy chủ');
  }
} 