import { create } from 'zustand';
import { LecturerAccount } from '@/types';
import { 
  getLecturerAccounts,
  createLecturerAccount,
  deleteLecturerAccount,
  toggleLecturerAccount,
} from '@/services/lecturerAccountService';

interface LecturerAccountsState {
  // Data
  accounts: LecturerAccount[];
  loading: boolean;
  error: string | null;
  selectedFaculty: string | null;
  
  // Actions
  fetchAccounts: (makhoa?: string) => Promise<void>;
  createAccount: (data: {
    loginname: string;
    password: string;
    userid: string;
    role: 'pgv_role' | 'khoa_role';
  }) => Promise<void>;
  deleteAccount: (magv: string) => Promise<void>;
  toggleAccount: (magv: string, disable: boolean) => Promise<void>;
  setSelectedFaculty: (makhoa: string | null) => void;
  reset: () => void;
}

export const useLecturerAccountsStore = create<LecturerAccountsState>((set, get) => ({
  // Initial state
  accounts: [],
  loading: false,
  error: null,
  selectedFaculty: null,
  
  // Actions
  fetchAccounts: async (makhoa?: string) => {
    set({ loading: true, error: null });
    try {
      const accounts = await getLecturerAccounts(makhoa);
      set({ accounts, loading: false });
    } catch (error) {
      console.error('Error fetching lecturer accounts:', error);
      set({ 
        error: error instanceof Error ? error.message : 'Lỗi không xác định', 
        loading: false 
      });
    }
  },
  
  createAccount: async (data) => {
    set({ loading: true, error: null });
    try {
      await createLecturerAccount(data);
      // Refresh accounts list after creation
      await get().fetchAccounts(get().selectedFaculty || undefined);
    } catch (error) {
      console.error('Error creating lecturer account:', error);
      set({ 
        error: error instanceof Error ? error.message : 'Lỗi không xác định', 
        loading: false 
      });
      throw error; // Re-throw to handle in UI
    }
  },
  
  deleteAccount: async (magv) => {
    set({ loading: true, error: null });
    try {
      await deleteLecturerAccount(magv);
      // Refresh accounts list after deletion
      await get().fetchAccounts(get().selectedFaculty || undefined);
    } catch (error) {
      console.error('Error deleting lecturer account:', error);
      set({ 
        error: error instanceof Error ? error.message : 'Lỗi không xác định', 
        loading: false 
      });
      throw error; // Re-throw to handle in UI
    }
  },
  
  toggleAccount: async (magv, disable) => {
    set({ loading: true, error: null });
    try {
      await toggleLecturerAccount(magv, disable);
      // Refresh list
      await get().fetchAccounts(get().selectedFaculty || undefined);
    } catch (error) {
      console.error('Error toggling lecturer account:', error);
      set({
        error: error instanceof Error ? error.message : 'Lỗi không xác định',
        loading: false,
      });
      throw error;
    }
  },
  
  setSelectedFaculty: (makhoa) => {
    set({ selectedFaculty: makhoa });
  },
  
  reset: () => {
    set({ 
      accounts: [],
      loading: false,
      error: null,
      selectedFaculty: null
    });
  }
})); 