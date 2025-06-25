import { create } from 'zustand';
import { LopTinChi, LopTinChiFilter, DangKy } from '@/types';
import * as loptinchiService from '@/services/loptinchiService';

interface LopTinChiState {
  // State
  loptinchiList: LopTinChi[];
  registrations: DangKy[];
  filters: LopTinChiFilter;
  isLoading: boolean;
  error: string | null;
  
  // Actions
  setLopTinChiList: (list: LopTinChi[]) => void;
  setRegistrations: (registrations: DangKy[]) => void;
  setFilters: (filters: Partial<LopTinChiFilter>) => void;
  setIsLoading: (isLoading: boolean) => void;
  setError: (error: string | null) => void;
  
  // Async actions
  fetchLopTinChiList: () => Promise<void>;
  fetchStudentRegistrations: (masv: string) => Promise<void>;
  registerCourse: (maltc: number, masv: string) => Promise<void>;
  cancelRegistration: (maltc: number, masv: string) => Promise<void>;
}

export const useLopTinChiStore = create<LopTinChiState>()((set, get) => ({
  // Initial state
  loptinchiList: [],
  registrations: [],
  filters: {
    only_available: true
  },
  isLoading: false,
  error: null,
  
  // State setters
  setLopTinChiList: (list) => set({ loptinchiList: list }),
  setRegistrations: (registrations) => set({ registrations }),
  setFilters: (filters) => set({ filters: { ...get().filters, ...filters } }),
  setIsLoading: (isLoading) => set({ isLoading }),
  setError: (error) => set({ error }),
  
  // Async actions
  fetchLopTinChiList: async () => {
    const { filters } = get();
    set({ isLoading: true, error: null });
    
    try {
      const data = await loptinchiService.getLopTinChiList(filters);
      set({ loptinchiList: data, isLoading: false });
    } catch (error) {
      set({ 
        error: error instanceof Error ? error.message : 'Không thể lấy danh sách lớp tín chỉ',
        isLoading: false 
      });
    }
  },
  
  fetchStudentRegistrations: async (masv) => {
    set({ isLoading: true, error: null });
    
    try {
      const data = await loptinchiService.getStudentRegistrations(masv);
      set({ registrations: data, isLoading: false });
    } catch (error) {
      set({ 
        error: error instanceof Error ? error.message : 'Không thể lấy danh sách đăng ký',
        isLoading: false 
      });
    }
  },
  
  registerCourse: async (maltc, masv) => {
    set({ isLoading: true, error: null });
    
    try {
      await loptinchiService.registerCourse({ MALTC: maltc, MASV: masv });
      
      // Refresh both lists after successful registration
      await get().fetchLopTinChiList();
      await get().fetchStudentRegistrations(masv);
      
      set({ isLoading: false });
    } catch (error) {
      set({ 
        error: error instanceof Error ? error.message : 'Không thể đăng ký lớp tín chỉ',
        isLoading: false 
      });
    }
  },
  
  cancelRegistration: async (maltc, masv) => {
    set({ isLoading: true, error: null });
    
    try {
      await loptinchiService.cancelRegistration({ MALTC: maltc, MASV: masv });
      
      // Refresh both lists after successful cancellation
      await get().fetchLopTinChiList();
      await get().fetchStudentRegistrations(masv);
      
      set({ isLoading: false });
    } catch (error) {
      set({ 
        error: error instanceof Error ? error.message : 'Không thể hủy đăng ký lớp tín chỉ',
        isLoading: false 
      });
    }
  }
})); 