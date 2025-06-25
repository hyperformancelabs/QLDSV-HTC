import { API_BASE_URL } from '@/lib/config';
import { 
  LopTinChi, 
  LopTinChiFilter, 
  LopTinChiUpsert, 
  DangKy, 
  DangKyCreate, 
  DangKyCancel,
  StudentInfo
} from '@/types';

const BASE_URL = `${API_BASE_URL}/loptinchi`;

/**
 * Fetch list of LopTinChi with optional filters
 */
export async function getLopTinChiList(filters?: LopTinChiFilter): Promise<LopTinChi[]> {
  let url = BASE_URL;
  
  if (filters) {
    const params = new URLSearchParams();
    if (filters.nienkhoa) params.append('nienkhoa', filters.nienkhoa);
    if (filters.hocky !== undefined) params.append('hocky', filters.hocky.toString());
    if (filters.makhoa) params.append('makhoa', filters.makhoa);
    if (filters.only_available) params.append('only_available', 'true');
    
    if (params.toString()) {
      url += `?${params.toString()}`;
    }
  }
  
  const response = await fetch(url, {
    method: 'GET',
    credentials: 'include',
  });
  
  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(errorText || 'Không thể lấy danh sách lớp tín chỉ');
  }
  
  return response.json();
}

/**
 * Create a new LopTinChi
 */
export async function createLopTinChi(data: LopTinChiUpsert): Promise<{ message: string; maltc: number }> {
  const response = await fetch(BASE_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(data),
    credentials: 'include',
  });
  
  if (!response.ok) {
    const errorData = await response.json();
    throw new Error(errorData.detail || 'Không thể tạo lớp tín chỉ');
  }
  
  return response.json();
}

/**
 * Update an existing LopTinChi
 */
export async function updateLopTinChi(maltc: number, data: LopTinChiUpsert): Promise<{ message: string }> {
  const response = await fetch(`${BASE_URL}/${maltc}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(data),
    credentials: 'include',
  });
  
  if (!response.ok) {
    const errorData = await response.json();
    throw new Error(errorData.detail || 'Không thể cập nhật lớp tín chỉ');
  }
  
  return response.json();
}

/**
 * Cancel (soft delete) a LopTinChi
 */
export async function cancelLopTinChi(maltc: number): Promise<{ message: string }> {
  const response = await fetch(`${BASE_URL}/${maltc}`, {
    method: 'DELETE',
    credentials: 'include',
  });
  
  if (!response.ok) {
    const errorData = await response.json();
    throw new Error(errorData.detail || 'Không thể hủy lớp tín chỉ');
  }
  
  return response.json();
}

/**
 * Restore a previously canceled LopTinChi
 */
export async function restoreLopTinChi(maltc: number): Promise<{ message: string }> {
  const response = await fetch(`${BASE_URL}/${maltc}/restore`, {
    method: 'POST',
    credentials: 'include',
  });
  
  if (!response.ok) {
    const errorData = await response.json();
    throw new Error(errorData.detail || 'Không thể khôi phục lớp tín chỉ');
  }
  
  return response.json();
}

/**
 * Register a student for a LopTinChi
 */
export async function registerCourse(data: DangKyCreate): Promise<{ message: string }> {
  const response = await fetch(`${BASE_URL}/register`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(data),
    credentials: 'include',
  });
  
  if (!response.ok) {
    const errorData = await response.json();
    throw new Error(errorData.detail || 'Không thể đăng ký lớp tín chỉ');
  }
  
  return response.json();
}

/**
 * Cancel a student's registration for a LopTinChi
 */
export async function cancelRegistration(data: DangKyCancel): Promise<{ message: string }> {
  const response = await fetch(`${BASE_URL}/cancel-registration`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(data),
    credentials: 'include',
  });
  
  if (!response.ok) {
    const errorData = await response.json();
    throw new Error(errorData.detail || 'Không thể hủy đăng ký lớp tín chỉ');
  }
  
  return response.json();
}

/**
 * Get a list of registrations for a student
 */
export async function getStudentRegistrations(masv: string): Promise<DangKy[]> {
  const response = await fetch(`${BASE_URL}/student/${masv}/registrations`, {
    method: 'GET',
    credentials: 'include',
  });
  
  if (!response.ok) {
    const errorData = await response.json();
    throw new Error(errorData.detail || 'Không thể lấy danh sách đăng ký của sinh viên');
  }
  
  return response.json();
}

/**
 * Get basic information about a student
 */
export async function getStudentInfo(masv: string): Promise<StudentInfo> {
  const response = await fetch(`${BASE_URL}/student/${masv}/info`, {
    method: 'GET',
    credentials: 'include',
  });
  
  if (!response.ok) {
    const errorData = await response.json();
    throw new Error(errorData.detail || 'Không thể lấy thông tin sinh viên');
  }
  
  return response.json();
} 