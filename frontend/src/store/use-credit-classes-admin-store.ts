import { create } from 'zustand';
import { LopTinChi, LopTinChiUpsert } from '@/types';

export interface LopTinChiWithMeta extends LopTinChi {
  isNew?: boolean;
  isModified?: boolean;
  isDeleted?: boolean;
  originalData?: LopTinChi;
}

export type LopTinChiAction =
  | { type: 'ADD'; item: LopTinChiWithMeta }
  | { type: 'EDIT'; item: LopTinChiWithMeta; original: LopTinChiWithMeta }
  | { type: 'DELETE'; item: LopTinChiWithMeta };

interface CreditClassState {
  // Data & stack
  creditClasses: LopTinChiWithMeta[];
  originalCreditClasses: LopTinChi[];
  actionsStack: LopTinChiAction[];

  // Mutations
  setCreditClasses: (data: LopTinChi[]) => void;
  addClass: (data: LopTinChi) => void;
  editClass: (data: LopTinChi) => void;
  toggleCancelClass: (maltc: number) => void; // cancel / restore
  undo: () => void;
  resetChanges: () => void;
  saveChanges: () => {
    toCreate: LopTinChiUpsert[];
    toUpdate: { maltc: number; data: LopTinChiUpsert }[];
    toCancel: number[];
    toRestore: number[];
  };
  hasChanges: () => boolean;

  // derived helpers (no filters here, handled in page)
}

export const useCreditClassesAdminStore = create<CreditClassState>()((set, get) => ({
  creditClasses: [],
  originalCreditClasses: [],
  actionsStack: [],

  setCreditClasses: (data) => {
    set({
      creditClasses: data.map((c) => ({ ...c })),
      originalCreditClasses: data.map((c) => ({ ...c })),
      actionsStack: [],
    });
  },

  addClass: (data) => {
    // generate temp MALTC if not provided
    const tempId = data.MALTC ?? Date.now() * -1;
    const newItem: LopTinChiWithMeta = {
      ...data,
      MALTC: tempId,
      SOSVDANGKY: data.SOSVDANGKY ?? 0,
      HUYLOP: data.HUYLOP ?? false,
      isNew: true,
    } as LopTinChiWithMeta;

    set((state) => ({
      creditClasses: [...state.creditClasses, newItem],
      actionsStack: [...state.actionsStack, { type: 'ADD', item: newItem }],
    }));
  },

  editClass: (data) => {
    set((state) => {
      const index = state.creditClasses.findIndex((c) => c.MALTC === data.MALTC);
      if (index === -1) return state;

      const original = state.creditClasses[index];
      const updated: LopTinChiWithMeta = {
        ...data,
        isModified: true,
        originalData: original.originalData || original,
      } as LopTinChiWithMeta;

      const newList = [...state.creditClasses];
      newList[index] = updated;

      return {
        creditClasses: newList,
        actionsStack: [
          ...state.actionsStack,
          { type: 'EDIT', item: updated, original: original },
        ],
      };
    });
  },

  toggleCancelClass: (maltc) => {
    set((state) => {
      const idx = state.creditClasses.findIndex((c) => c.MALTC === maltc);
      if (idx === -1) return state;

      const target = state.creditClasses[idx];
      const newItem = {
        ...target,
        isDeleted: !target.isDeleted,
        HUYLOP: !target.HUYLOP,
      } as LopTinChiWithMeta;

      const newList = [...state.creditClasses];
      newList[idx] = newItem;

      return {
        creditClasses: newList,
        actionsStack: [...state.actionsStack, { type: 'DELETE', item: newItem }],
      };
    });
  },

  undo: () => {
    set((state) => {
      if (state.actionsStack.length === 0) return state;
      const newStack = [...state.actionsStack];
      const action = newStack.pop() as LopTinChiAction | undefined;
      if (!action) return state;

      let list = [...state.creditClasses];
      switch (action.type) {
        case 'ADD':
          list = list.filter((c) => c.MALTC !== action.item.MALTC);
          break;
        case 'EDIT': {
          const i = list.findIndex((c) => c.MALTC === action.original.MALTC);
          if (i !== -1) {
            list[i] = {
              ...action.original,
              isModified: false,
            } as LopTinChiWithMeta;
          }
          break;
        }
        case 'DELETE': {
          const i = list.findIndex((c) => c.MALTC === action.item.MALTC);
          if (i !== -1) {
            list[i] = {
              ...list[i],
              isDeleted: !list[i].isDeleted,
              HUYLOP: !list[i].HUYLOP,
            };
          }
          break;
        }
      }

      return { creditClasses: list, actionsStack: newStack };
    });
  },

  resetChanges: () => {
    set((state) => ({
      creditClasses: state.originalCreditClasses.map((c) => ({ ...c })),
      actionsStack: [],
    }));
  },

  saveChanges: () => {
    const state = get();

    const toCreate: LopTinChiUpsert[] = [];
    const toUpdate: { maltc: number; data: LopTinChiUpsert }[] = [];
    const toCancel: number[] = [];
    const toRestore: number[] = [];

    state.creditClasses.forEach((c) => {
      if (c.isNew && !c.isDeleted) {
        toCreate.push({
          NIENKHOA: c.NIENKHOA,
          HOCKY: c.HOCKY,
          MAMH: c.MAMH,
          NHOM: c.NHOM,
          MAGV: c.MAGV,
          MAKHOA: c.MAKHOA,
          SOSVTOITHIEU: c.SOSVTOITHIEU,
        });
      } else if (c.isModified && !c.isDeleted && !c.isNew) {
        toUpdate.push({
          maltc: c.MALTC,
          data: {
            NIENKHOA: c.NIENKHOA,
            HOCKY: c.HOCKY,
            MAMH: c.MAMH,
            NHOM: c.NHOM,
            MAGV: c.MAGV,
            MAKHOA: c.MAKHOA,
            SOSVTOITHIEU: c.SOSVTOITHIEU,
          },
        });
      } else if (c.isDeleted && !c.isNew) {
        toCancel.push(c.MALTC);
      }

      // Detect cancel / restore diff versus original
      if (!c.isNew) {
        const original = state.originalCreditClasses.find(o => o.MALTC === c.MALTC);
        if (original) {
          if (!original.HUYLOP && c.HUYLOP) {
            toCancel.push(c.MALTC);
          }
          if (original.HUYLOP && !c.HUYLOP) {
            toRestore.push(c.MALTC);
          }
        }
      }
    });

    return { toCreate, toUpdate, toCancel, toRestore };
  },

  hasChanges: () => get().actionsStack.length > 0,
})); 