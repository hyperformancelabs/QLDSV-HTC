import { LecturerAccount } from '@/types';
import { API_BASE_URL } from '@/lib/config';

// Base endpoint for lecturer APIs
const BASE_ENDPOINT = `${API_BASE_URL}/giangvien`;

/**
 * Lấy danh sách giảng viên và trạng thái tài khoản
 * @param makhoa Optional filter by faculty code
 * @returns List of lecturer accounts with login status
 */
export async function getLecturerAccounts(makhoa?: string): Promise<LecturerAccount[]> {
  // Build URL with query parameters for filtering
  const params = new URLSearchParams();
  if (makhoa) params.append('makhoa', makhoa);

  const url = `${BASE_ENDPOINT}${params.toString() ? '?' + params.toString() : ''}`;
  
  const response = await fetch(url, {
    method: 'GET',
    credentials: 'include',
    headers: {
      'Content-Type': 'application/json',
    },
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(error || 'Không thể lấy danh sách tài khoản giảng viên');
  }

  return response.json();
}

/**
 * Tìm kiếm giảng viên theo tên hoặc mã
 * @param query Search query (name or ID)
 * @returns List of matching lecturers
 */
export async function searchLecturers(query: string): Promise<LecturerAccount[]> {
  // Build URL with query parameters for filtering
  const url = `${BASE_ENDPOINT}${query.trim().length > 0 ? `?search=${encodeURIComponent(query)}` : ''}`;
  
  const response = await fetch(url, {
    method: 'GET',
    credentials: 'include',
    headers: {
      'Content-Type': 'application/json',
    },
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(error || 'Không thể tìm kiếm giảng viên');
  }

  const data = await response.json();
  return data || [];
}

/**
 * Tạo tài khoản mới cho giảng viên
 */
export async function createLecturerAccount(data: {
  loginname: string;
  password: string;
  userid: string; // MAGV of lecturer
  role: 'pgv_role' | 'khoa_role';
}): Promise<void> {
  const { loginname, password, userid, role } = data;

  const response = await fetch(`${BASE_ENDPOINT}/${encodeURIComponent(userid)}/account`, {
    method: 'POST',
    credentials: 'include',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ loginname, password, role }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(error || 'Không thể tạo tài khoản giảng viên');
  }
}

/**
 * Thu hồi tài khoản giảng viên
 * @param magv Lecturer ID
 */
export async function deleteLecturerAccount(magv: string): Promise<void> {
  const response = await fetch(`${BASE_ENDPOINT}/${encodeURIComponent(magv.trim())}/account`, {
    method: 'DELETE',
    credentials: 'include',
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(error || 'Không thể thu hồi tài khoản giảng viên');
  }
}

/**
 * Vô hiệu hoá / kích hoạt tài khoản giảng viên
 */
export async function toggleLecturerAccount(magv: string, disable: boolean): Promise<void> {
  const response = await fetch(`${BASE_ENDPOINT}/${encodeURIComponent(magv.trim())}/account/toggle`, {
    method: 'PATCH',
    credentials: 'include',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ is_disabled: disable }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(error || 'Không thể thay đổi trạng thái tài khoản');
  }
} 