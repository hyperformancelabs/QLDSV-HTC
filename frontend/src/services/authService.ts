import { User, UserRole } from '@/types';
import { API_BASE_URL } from '@/lib/config';

export const LOGIN_ENDPOINT = `${API_BASE_URL}/auth/login`;
export const LOGOUT_ENDPOINT = `${API_BASE_URL}/auth/logout`;
export const ME_ENDPOINT = `${API_BASE_URL}/auth/me`;

interface LoginCredentials {
  username: string;
  password: string;
}

/**
 * Convert backend user info into frontend `User` model.
 */
function mapBackendUser(data: { username: string; fullname: string; role: string }): User {
  // Split fullname => last token = tên, phần còn lại = họ
  const parts = data.fullname.trim().split(' ');
  const ten = parts.pop() || '';
  const ho = parts.join(' ');

  let role: UserRole;
  switch (data.role) {
    case 'pgv_role':
      role = UserRole.PGV;
      break;
    case 'khoa_role':
      role = UserRole.KHOA;
      break;
    default:
      role = UserRole.SV;
  }

  return {
    id: data.username,
    username: data.username,
    ho,
    ten,
    role,
    masv: role === UserRole.SV ? data.username : undefined,
    magv: role !== UserRole.SV ? data.username : undefined,
  };
}

/**
 * Thực hiện đăng nhập. Hàm sẽ trả về đối tượng `User` nếu thành công.
 */
export async function login(credentials: LoginCredentials): Promise<User> {
  const res = await fetch(LOGIN_ENDPOINT, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(credentials),
    credentials: 'include', // quan trọng để nhận cookie session
  });

  if (!res.ok) {
    const errorText = await res.text();
    throw new Error(errorText || 'Đăng nhập thất bại');
  }

  const data = await res.json();
  return mapBackendUser(data);
}

/**
 * Đăng xuất – huỷ phiên ở phía server và xóa cookie.
 */
export async function logout(): Promise<void> {
  await fetch(LOGOUT_ENDPOINT, {
    method: 'POST',
    credentials: 'include',
  });
}

/**
 * Lấy thông tin người dùng hiện tại dựa trên session cookie.
 */
export async function getCurrentUser(): Promise<User | null> {
  const res = await fetch(ME_ENDPOINT, {
    method: 'GET',
    credentials: 'include',
  });

  if (res.status === 401) return null;
  if (!res.ok) throw new Error('Không thể lấy thông tin người dùng');

  const data = await res.json();
  return mapBackendUser(data);
}

/**
 * Checks if a token is valid
 * @param token JWT token
 * @returns Promise with boolean indicating if token is valid
 */
export async function validateToken(token: string): Promise<boolean> {
  // Simulate API call delay
  await new Promise(resolve => setTimeout(resolve, 300));
  
  // In a real app, we would validate the token on the server
  // For demo, we'll just return true if the token exists
  return !!token && token.startsWith('mock-jwt-token-');
} 