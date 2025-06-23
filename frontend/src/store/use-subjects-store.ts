import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { Subject, SubjectWithMeta, SubjectAction } from '@/services/subjectService';

type SubjectsState = {
  // Data
  subjects: SubjectWithMeta[];
  originalSubjects: Subject[]; // Original data from server
  actionsStack: SubjectAction[]; // For undo/redo
  searchTerm: string;
  sortField: keyof Subject;
  sortDirection: 'asc' | 'desc';
  pageSize: number;
  currentPage: number;
  
  // Actions
  setSubjects: (subjects: Subject[]) => void;
  addSubject: (subject: Subject) => void;
  editSubject: (subject: Subject) => void;
  deleteSubject: (mamh: string) => void;
  undo: () => void;
  resetChanges: () => void;
  saveChanges: () => { toSave: Subject[]; toDelete: string[] };
  hasChanges: () => boolean;
  
  // Search and pagination
  setSearchTerm: (term: string) => void;
  setSortField: (field: keyof Subject) => void;
  toggleSortDirection: () => void;
  setPageSize: (size: number) => void;
  setCurrentPage: (page: number) => void;
  
  // Computed helpers
  filteredSubjects: () => SubjectWithMeta[];
  paginatedSubjects: () => SubjectWithMeta[];
  totalPages: () => number;
};

export const useSubjectsStore = create<SubjectsState>()(
  // persist(
    (set, get) => ({
      // Initial state
      subjects: [],
      originalSubjects: [],
      actionsStack: [],
      searchTerm: '',
      sortField: 'MAMH',
      sortDirection: 'asc',
      pageSize: 10,
      currentPage: 1,
      
      // Data actions
      setSubjects: (subjects) => {
        set({ 
          subjects: subjects.map(s => ({ ...s })),
          originalSubjects: subjects.map(s => ({ ...s })),
          actionsStack: []
        });
      },
      
      addSubject: (subject) => {
        // Create a new subject with metadata
        const newSubject: SubjectWithMeta = {
          ...subject,
          isNew: true
        };
        
        // Add action to stack for undo
        set(state => ({
          subjects: [...state.subjects, newSubject],
          actionsStack: [...state.actionsStack, { type: 'ADD', subject: newSubject }]
        }));
      },
      
      editSubject: (subject) => {
        set(state => {
          const index = state.subjects.findIndex(s => s.MAMH === subject.MAMH);
          if (index === -1) return state;
          
          const original = state.subjects[index];
          const updated = { 
            ...subject,
            isModified: true,
            originalData: original.originalData || original
          };
          
          // Copy array and replace the edited item
          const newSubjects = [...state.subjects];
          newSubjects[index] = updated;
          
          return {
            subjects: newSubjects,
            actionsStack: [...state.actionsStack, { 
              type: 'EDIT', 
              subject: updated,
              original: original.originalData || original
            }]
          };
        });
      },
      
      deleteSubject: (mamh) => {
        set(state => {
          const index = state.subjects.findIndex(s => s.MAMH === mamh);
          if (index === -1) return state;
          
          const subject = state.subjects[index];
          
          // Mark the subject as deleted (even if it's new)
          const newSubjects = [...state.subjects];
          newSubjects[index] = {
            ...subject,
            isDeleted: true,
            originalData: subject.originalData || subject
          };
          
          return {
            subjects: newSubjects,
            actionsStack: [...state.actionsStack, { type: 'DELETE', subject }]
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
          
          let newSubjects = [...state.subjects];
          
          switch (action.type) {
            case 'ADD':
              // Remove the added subject
              newSubjects = newSubjects.filter(s => s.MAMH !== action.subject.MAMH);
              break;
              
            case 'EDIT':
              // Revert to original
              const editIndex = newSubjects.findIndex(s => s.MAMH === action.original.MAMH);
              if (editIndex !== -1) {
                newSubjects[editIndex] = {
                  ...action.original,
                  originalData: (action.original as SubjectWithMeta).originalData
                };
              }
              break;
              
            case 'DELETE':
              // Unmark deleted
              const deleteIndex = newSubjects.findIndex(s => s.MAMH === action.subject.MAMH);
              if (deleteIndex !== -1) {
                // Was marked as deleted, unmark it
                newSubjects[deleteIndex] = {
                  ...newSubjects[deleteIndex],
                  isDeleted: false
                };
              }
              break;
          }
          
          return {
            subjects: newSubjects,
            actionsStack: newStack
          };
        });
      },
      
      resetChanges: () => {
        set(state => ({
          subjects: state.originalSubjects.map(s => ({ ...s })),
          actionsStack: []
        }));
      },
      
      saveChanges: () => {
        // Returns the subjects that need to be saved and deleted
        const state = get();
        const toSave: Subject[] = [];
        
        // Find all that need to be saved (added or modified)
        state.subjects.forEach(subject => {
          if ((subject.isNew || subject.isModified) && !subject.isDeleted) {
            // Clean up the subject (remove metadata)
            const clean: Subject = {
              MAMH: subject.MAMH,
              TENMH: subject.TENMH,
              SOTIET_LT: subject.SOTIET_LT,
              SOTIET_TH: subject.SOTIET_TH,
              IS_LINKED: subject.IS_LINKED
            };
            toSave.push(clean);
          }
        });
        
        // Get subjects to delete
        const toDelete = state.subjects
          .filter(s => s.isDeleted)
          .map(s => s.MAMH);
        
        console.log('Subjects to save:', toSave);
        console.log('Subjects to delete:', toDelete);
        
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
      filteredSubjects: () => {
        const state = get();
        // Include deleted subjects instead of filtering them out
        let filtered = state.subjects;
        
        // Apply search filter if any
        if (state.searchTerm) {
          const term = state.searchTerm.toLowerCase();
          filtered = filtered.filter(s => 
            s.MAMH.toLowerCase().includes(term) || 
            s.TENMH.toLowerCase().includes(term)
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
      
      paginatedSubjects: () => {
        const filtered = get().filteredSubjects();
        const start = (get().currentPage - 1) * get().pageSize;
        const end = start + get().pageSize;
        return filtered.slice(start, end);
      },
      
      totalPages: () => {
        return Math.ceil(get().filteredSubjects().length / get().pageSize);
      }
    })
  // )
); 