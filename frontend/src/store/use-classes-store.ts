import { create } from 'zustand';
import { Class, ClassWithMeta, ClassAction } from '@/services/classService';

type ClassesState = {
  // Data
  classes: ClassWithMeta[];
  originalClasses: Class[]; // Original data from server
  actionsStack: ClassAction[]; // For undo/redo
  searchTerm: string;
  sortField: keyof Class;
  sortDirection: 'asc' | 'desc';
  pageSize: number;
  currentPage: number;
  selectedClass: ClassWithMeta | null; // Currently selected class for student management
  
  // Actions
  setClasses: (classes: Class[]) => void;
  addClass: (cls: Class) => void;
  editClass: (cls: Class) => void;
  deleteClass: (malop: string) => void;
  selectClass: (malop: string | null) => void;
  undo: () => void;
  resetChanges: () => void;
  saveChanges: () => { toSave: Class[]; toDelete: string[] };
  hasChanges: () => boolean;
  
  // Search and pagination
  setSearchTerm: (term: string) => void;
  setSortField: (field: keyof Class) => void;
  toggleSortDirection: () => void;
  setPageSize: (size: number) => void;
  setCurrentPage: (page: number) => void;
  
  // Computed helpers
  filteredClasses: () => ClassWithMeta[];
  paginatedClasses: () => ClassWithMeta[];
  totalPages: () => number;
};

export const useClassesStore = create<ClassesState>()(
  (set, get) => ({
    // Initial state
    classes: [],
    originalClasses: [],
    actionsStack: [],
    searchTerm: '',
    sortField: 'TENLOP',
    sortDirection: 'asc',
    pageSize: 10,
    currentPage: 1,
    selectedClass: null,
    
    // Data actions
    setClasses: (classes) => {
      set({ 
        classes: classes.map(c => ({ ...c })),
        originalClasses: classes.map(c => ({ ...c })),
        actionsStack: []
      });
    },
    
    addClass: (cls) => {
      // Create a new class with metadata
      const newClass: ClassWithMeta = {
        ...cls,
        isNew: true
      };
      
      // Add action to stack for undo
      set(state => ({
        classes: [...state.classes, newClass],
        actionsStack: [...state.actionsStack, { type: 'ADD', class: newClass }]
      }));
    },
    
    editClass: (cls) => {
      set(state => {
        const index = state.classes.findIndex(c => c.MALOP === cls.MALOP);
        if (index === -1) return state;
        
        const original = state.classes[index];
        const updated = { 
          ...cls,
          isModified: true,
          originalData: original.originalData || original
        };
        
        // Copy array and replace the edited item
        const newClasses = [...state.classes];
        newClasses[index] = updated;
        
        // If this is the selected class, update that too
        let newSelected = state.selectedClass;
        if (state.selectedClass?.MALOP === cls.MALOP) {
          newSelected = updated;
        }
        
        return {
          classes: newClasses,
          selectedClass: newSelected,
          actionsStack: [...state.actionsStack, { 
            type: 'EDIT', 
            class: updated,
            original: original.originalData || original
          }]
        };
      });
    },
    
    deleteClass: (malop) => {
      set(state => {
        const index = state.classes.findIndex(c => c.MALOP === malop);
        if (index === -1) return state;
        
        const cls = state.classes[index];
        
        // Mark the class as deleted (even if it's new)
        const newClasses = [...state.classes];
        newClasses[index] = {
          ...cls,
          isDeleted: true,
          originalData: cls.originalData || cls
        };
        
        // If this is the selected class, deselect it
        let newSelected = state.selectedClass;
        if (state.selectedClass?.MALOP === malop) {
          newSelected = null;
        }
        
        return {
          classes: newClasses,
          selectedClass: newSelected,
          actionsStack: [...state.actionsStack, { type: 'DELETE', class: cls }]
        };
      });
    },
    
    selectClass: (malop) => {
      if (!malop) {
        set({ selectedClass: null });
        return;
      }
      
      const cls = get().classes.find(c => c.MALOP === malop);
      set({ selectedClass: cls || null });
    },
    
    undo: () => {
      set(state => {
        if (state.actionsStack.length === 0) return state;
        
        // Pop last action
        const newStack = [...state.actionsStack];
        const action = newStack.pop();
        if (!action) return state;
        
        let newClasses = [...state.classes];
        let newSelected = state.selectedClass;
        
        switch (action.type) {
          case 'ADD':
            // Remove the added class
            newClasses = newClasses.filter(c => c.MALOP !== action.class.MALOP);
            
            // If this was the selected class, deselect it
            if (state.selectedClass?.MALOP === action.class.MALOP) {
              newSelected = null;
            }
            break;
            
          case 'EDIT':
            // Revert to original
            const editIndex = newClasses.findIndex(c => c.MALOP === action.original.MALOP);
            if (editIndex !== -1) {
              newClasses[editIndex] = {
                ...action.original,
                originalData: (action.original as ClassWithMeta).originalData
              };
              
              // If this is the selected class, update that too
              if (state.selectedClass?.MALOP === action.original.MALOP) {
                newSelected = newClasses[editIndex];
              }
            }
            break;
            
          case 'DELETE':
            // Unmark deleted
            const deleteIndex = newClasses.findIndex(c => c.MALOP === action.class.MALOP);
            if (deleteIndex !== -1) {
              // Was marked as deleted, unmark it
              newClasses[deleteIndex] = {
                ...newClasses[deleteIndex],
                isDeleted: false
              };
              
              // If this was previously selected, re-select it
              if (!state.selectedClass && action.class.MALOP === newClasses[deleteIndex].MALOP) {
                newSelected = newClasses[deleteIndex];
              }
            }
            break;
        }
        
        return {
          classes: newClasses,
          selectedClass: newSelected,
          actionsStack: newStack
        };
      });
    },
    
    resetChanges: () => {
      const originalSelected = get().selectedClass?.MALOP;
      
      set(state => {
        const newClasses = state.originalClasses.map(c => ({ ...c }));
        
        // Try to re-select the previously selected class
        let newSelected = null;
        if (originalSelected) {
          newSelected = newClasses.find(c => c.MALOP === originalSelected) || null;
        }
        
        return {
          classes: newClasses,
          selectedClass: newSelected,
          actionsStack: []
        };
      });
    },
    
    saveChanges: () => {
      // Returns the classes that need to be saved and deleted
      const state = get();
      const toSave: Class[] = [];
      
      // Find all that need to be saved (added or modified)
      state.classes.forEach(cls => {
        if ((cls.isNew || cls.isModified) && !cls.isDeleted) {
          // Clean up the class (remove metadata)
          const clean: Class = {
            MALOP: cls.MALOP,
            TENLOP: cls.TENLOP,
            KHOAHOC: cls.KHOAHOC,
            MAKHOA: cls.MAKHOA,
            SOLUONGSV: cls.SOLUONGSV
          };
          toSave.push(clean);
        }
      });
      
      // Get classes to delete
      const toDelete = state.classes
        .filter(c => c.isDeleted)
        .map(c => c.MALOP);
      
      console.log('Classes to save:', toSave);
      console.log('Classes to delete:', toDelete);
      
      return { toSave, toDelete };
    },
    
    hasChanges: () => {
      const state = get();
      return state.actionsStack.length > 0;
    },
    
    // Search & pagination
    setSearchTerm: (term) => set({ searchTerm: term, currentPage: 1 }),
    setSortField: (field) => set({ sortField: field }),
    toggleSortDirection: () => set(state => ({ 
      sortDirection: state.sortDirection === 'asc' ? 'desc' : 'asc' 
    })),
    setPageSize: (size) => set({ pageSize: size, currentPage: 1 }),
    setCurrentPage: (page) => set({ currentPage: page }),
    
    // Computed helpers
    filteredClasses: () => {
      const state = get();
      // Include deleted classes in the filtered result
      let filtered = state.classes;
      
      // Apply search filter if any
      if (state.searchTerm) {
        const term = state.searchTerm.toLowerCase();
        filtered = filtered.filter(c => 
          c.MALOP.toLowerCase().includes(term) || 
          c.TENLOP.toLowerCase().includes(term) ||
          c.KHOAHOC.toLowerCase().includes(term)
        );
      }
      
      // Apply sorting
      filtered.sort((a, b) => {
        const field = state.sortField;
        const dir = state.sortDirection === 'asc' ? 1 : -1;
        
        if (a[field] < b[field]) return -1 * dir;
        if (a[field] > b[field]) return 1 * dir;
        return 0;
      });
      
      return filtered;
    },
    
    paginatedClasses: () => {
      const state = get();
      const filtered = state.filteredClasses();
      
      const start = (state.currentPage - 1) * state.pageSize;
      const end = start + state.pageSize;
      
      return filtered.slice(start, end);
    },
    
    totalPages: () => {
      const state = get();
      const filtered = state.filteredClasses();
      return Math.ceil(filtered.length / state.pageSize) || 1;
    },
  })
); 