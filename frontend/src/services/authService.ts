import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api/v1';

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  withCredentials: true, // Important for session-based auth
  headers: {
    'Content-Type': 'application/json',
  },
});

// Types for API responses
export interface LoginRequest {
  id: string;
  password: string;
  user_type: 'student' | 'teacher';
}

export interface LoginResponse {
  status: string;
  user: {
    masv?: string;
    magv?: string;
    ho: string;
    ten: string;
    role: string;
    [key: string]: any;
  };
}

export interface StudentSearchResult {
  masv: string;
  ho: string;
  ten: string;
  display_name: string;
}

export interface TeacherSearchResult {
  magv: string;
  ho: string;
  ten: string;
  display_name: string;
}

export interface StudentDetail {
  masv: string;
  ho: string;
  ten: string;
  malop: string;
  phai: boolean;
  ngaysinh: string;
  diachi: string;
}

export interface TeacherDetail {
  magv: string;
  ho: string;
  ten: string;
  makhoa: string;
  hocvi?: string;
  hocham?: string;
  chuyenmon?: string;
}

class AuthService {
  // Login function
  async login(loginData: LoginRequest): Promise<LoginResponse> {
    try {
      const response = await apiClient.post('/auth/login', loginData);
      return response.data;
    } catch (error: any) {
      if (error.response?.status === 401) {
        throw new Error('Tên đăng nhập hoặc mật khẩu không đúng');
      } else if (error.response?.status === 400) {
        throw new Error('Thông tin đăng nhập không hợp lệ');
      } else {
        throw new Error('Lỗi hệ thống, vui lòng thử lại sau');
      }
    }
  }

  // Logout function
  async logout(): Promise<void> {
    try {
      await apiClient.post('/auth/logout');
    } catch (error) {
      console.error('Logout error:', error);
    }
  }

  // Get current user info
  async getCurrentUser(): Promise<any> {
    try {
      const response = await apiClient.get('/auth/me');
      return response.data;
    } catch (error) {
      throw new Error('Không thể lấy thông tin người dùng');
    }
  }

  // Search students by name or ID
  async searchStudents(searchTerm: string): Promise<StudentSearchResult[]> {
    try {
      const response = await apiClient.get(`/auth/students/search?search_term=${encodeURIComponent(searchTerm)}`);
      return response.data;
    } catch (error) {
      console.error('Student search error:', error);
      return [];
    }
  }

  // Get student by ID
  async getStudentById(masv: string): Promise<StudentDetail> {
    try {
      const response = await apiClient.get(`/auth/students/${masv}`);
      return response.data;
    } catch (error: any) {
      throw new Error('Không tìm thấy sinh viên');
    }
  }

  // Search teachers by name or ID
  async searchTeachers(searchTerm: string): Promise<TeacherSearchResult[]> {
    try {
      const response = await apiClient.get(`/auth/teachers/search?search_term=${encodeURIComponent(searchTerm)}`);
      return response.data;
    } catch (error) {
      console.error('Teacher search error:', error);
      return [];
    }
  }

  // Get teacher by ID
  async getTeacherById(magv: string): Promise<TeacherDetail> {
    try {
      const response = await apiClient.get(`/auth/teachers/${magv}`);
      return response.data;
    } catch (error: any) {
      throw new Error('Không tìm thấy giảng viên');
    }
  }

  // Get all students for initial dropdown
  async getAllStudents(): Promise<StudentSearchResult[]> {
    try {
      const response = await apiClient.get('/auth/students');
      return response.data;
    } catch (error) {
      console.error('Get all students error:', error);
      return [];
    }
  }

  // Get all teachers for initial dropdown
  async getAllTeachers(): Promise<TeacherSearchResult[]> {
    try {
      const response = await apiClient.get('/auth/teachers');
      return response.data;
    } catch (error) {
      console.error('Get all teachers error:', error);
      return [];
    }
  }
}

export default new AuthService(); 