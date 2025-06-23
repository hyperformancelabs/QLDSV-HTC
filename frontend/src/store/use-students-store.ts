import { create } from 'zustand';
import { Student, StudentWithMeta, StudentAction, PaginatedStudents, fetchStudentsByClass } from '@/services/studentService';
import { ClassWithMeta } from '@/services/classService';

type StudentsState = {
  // Data
  students: StudentWithMeta[];
  originalStudents: Student[]; // Original data from server
  actionsStack: StudentAction[]; // For undo/redo
  searchTerm: string;
  sortField: keyof Student;
  sortDirection: 'ASC' | 'DESC';
  pageSize: number;
  currentPage: number;
  totalStudents: number;
  isLoading: boolean;
  currentClass: ClassWithMeta | null;
  editingStudent: StudentWithMeta | null;
  
  // Actions
  setStudentData: (data: PaginatedStudents) => void;
  setCurrentClass: (cls: ClassWithMeta | null) => void;
  addStudent: (student: Student) => void;
  editStudent: (student: Student) => void;
  setEditingStudent: (student: StudentWithMeta | null) => void;
  updateEditingStudent: (field: keyof Student, value: any) => void;
  cancelEditing: () => void;
  deleteStudent: (masv: string) => void;
  undo: () => void;
  resetChanges: () => void;
  
  // Search and pagination
  setSearchTerm: (term: string) => void;
  setSortField: (field: keyof Student) => void;
  toggleSortDirection: () => void;
  setPageSize: (size: number) => void;
  setCurrentPage: (page: number) => void;
  setLoading: (isLoading: boolean) => void;
  
  // Fetch operations
  fetchStudents: () => Promise<void>;
  hasChanges: () => boolean;
  getVisibleStudents: () => StudentWithMeta[];
};

export const useStudentsStore = create<StudentsState>()(
  (set, get) => ({
    // Initial state
    students: [],
    originalStudents: [],
    actionsStack: [],
    searchTerm: '',
    sortField: 'HO',
    sortDirection: 'ASC',
    pageSize: 10,
    currentPage: 1,
    totalStudents: 0,
    isLoading: false,
    currentClass: null,
    editingStudent: null,
    
    // Data actions
    setStudentData: (data) => {
      set({ 
        students: data.data.map(s => ({ ...s })),
        originalStudents: data.data.map(s => ({ ...s })),
        totalStudents: data.total,
        pageSize: data.page_size,
        currentPage: data.page,
        actionsStack: []
      });
    },
    
    setCurrentClass: (cls) => {
      set({ 
        currentClass: cls,
        students: [],
        originalStudents: [],
        actionsStack: [],
        totalStudents: 0,
        currentPage: 1,
        editingStudent: null
      });
      
      // Auto-fetch students when class is selected
      if (cls) {
        get().fetchStudents();
      }
    },
    
    addStudent: (student) => {
      // Create a new student with metadata
      const newStudent: StudentWithMeta = {
        ...student,
        isNew: true
      };
      
      // Add action to stack for undo
      set(state => ({
        students: [...state.students, newStudent],
        actionsStack: [...state.actionsStack, { type: 'ADD', student: newStudent }],
        totalStudents: state.totalStudents + 1,
        editingStudent: null
      }));
    },
    
    editStudent: (student) => {
      set(state => {
        const index = state.students.findIndex(s => s.MASV === student.MASV);
        if (index === -1) return state;
        
        const original = state.students[index];
        const updated = { 
          ...student,
          isModified: true,
          originalData: original.originalData || original
        };
        
        // Copy array and replace the edited item
        const newStudents = [...state.students];
        newStudents[index] = updated;
        
        return {
          students: newStudents,
          actionsStack: [...state.actionsStack, { 
            type: 'EDIT', 
            student: updated,
            original: original.originalData || original
          }],
          editingStudent: null
        };
      });
    },
    
    setEditingStudent: (student) => {
      set({ editingStudent: student ? { ...student } : null });
    },
    
    updateEditingStudent: (field, value) => {
      set(state => {
        if (!state.editingStudent) return state;
        
        return {
          editingStudent: {
            ...state.editingStudent,
            [field]: value
          }
        };
      });
    },
    
    cancelEditing: () => {
      set({ editingStudent: null });
    },
    
    deleteStudent: (masv) => {
      set(state => {
        const index = state.students.findIndex(s => s.MASV === masv);
        if (index === -1) return state;
        
        const student = state.students[index];
        
        // Mark the student as deleted (even if it's new)
        const newStudents = [...state.students];
        newStudents[index] = {
          ...student,
          isDeleted: true,
          originalData: student.originalData || student
        };
        
        return {
          students: newStudents,
          actionsStack: [...state.actionsStack, { type: 'DELETE', student }],
          totalStudents: state.totalStudents - 1,
          editingStudent: state.editingStudent?.MASV === masv ? null : state.editingStudent
        };
      });
    },
    
    undo: () => {
      set(state => {
        if (state.actionsStack.length === 0) return state;
        
        // Pop last action
        const newStack = [...state.actionsStack];
        const action = newStack.pop();
        if (!action) return state;
        
        let newStudents = [...state.students];
        let newTotalStudents = state.totalStudents;
        
        switch (action.type) {
          case 'ADD':
            // Remove the added student
            newStudents = newStudents.filter(s => s.MASV !== action.student.MASV);
            newTotalStudents--;
            break;
            
          case 'EDIT':
            // Revert to original
            const editIndex = newStudents.findIndex(s => s.MASV === action.original.MASV);
            if (editIndex !== -1) {
              newStudents[editIndex] = {
                ...action.original,
                originalData: (action.original as StudentWithMeta).originalData
              };
            }
            break;
            
          case 'DELETE':
            // Unmark deleted
            const deleteIndex = newStudents.findIndex(s => s.MASV === action.student.MASV);
            if (deleteIndex !== -1) {
              // Was marked as deleted, unmark it
              newStudents[deleteIndex] = {
                ...newStudents[deleteIndex],
                isDeleted: false
              };
              newTotalStudents++;
            }
            break;
        }
        
        return {
          students: newStudents,
          actionsStack: newStack,
          totalStudents: newTotalStudents
        };
      });
    },
    
    resetChanges: () => {
      set(state => ({
        students: state.originalStudents.map(s => ({ ...s })),
        actionsStack: [],
        totalStudents: state.originalStudents.length,
        editingStudent: null
      }));
    },
    
    // Search & pagination
    setSearchTerm: (term) => {
      set({ searchTerm: term, currentPage: 1 });
      get().fetchStudents();
    },
    
    setSortField: (field) => {
      set({ sortField: field });
      get().fetchStudents();
    },
    
    toggleSortDirection: () => {
      set(state => ({ 
        sortDirection: state.sortDirection === 'ASC' ? 'DESC' : 'ASC' 
      }));
      get().fetchStudents();
    },
    
    setPageSize: (size) => {
      set({ pageSize: size, currentPage: 1 });
      get().fetchStudents();
    },
    
    setCurrentPage: (page) => {
      set({ currentPage: page });
      get().fetchStudents();
    },
    
    setLoading: (isLoading) => {
      set({ isLoading });
    },
    
    // Fetch from API
    fetchStudents: async () => {
      const state = get();
      
      // Don't fetch if no class is selected
      if (!state.currentClass) return;
      
      try {
        state.setLoading(true);
        const data = await fetchStudentsByClass(
          state.currentClass.MALOP,
          state.currentPage,
          state.pageSize,
          state.searchTerm,
          state.sortField.toString(),
          state.sortDirection
        );
        state.setStudentData(data);
      } catch (error) {
        console.error('Error fetching students:', error);
      } finally {
        state.setLoading(false);
      }
    },
    
    hasChanges: () => {
      const state = get();
      return state.actionsStack.length > 0;
    },
    
    getVisibleStudents: () => {
      return get().students.filter(s => !s.isDeleted);
    }
  })
); 