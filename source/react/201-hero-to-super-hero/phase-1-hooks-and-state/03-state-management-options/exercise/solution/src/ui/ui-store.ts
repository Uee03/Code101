import { create } from 'zustand';

type UiState = {
  query: string;
  toast: string | null;
  compact: boolean;
  setQuery: (query: string) => void;
  showToast: (message: string) => void;
  clearToast: () => void;
  toggleCompact: () => void;
};

export const useUiStore = create<UiState>()((set) => ({
  query: '',
  toast: null,
  compact: false,
  setQuery: (query) => set({ query }),
  showToast: (message) => set({ toast: message }),
  clearToast: () => set({ toast: null }),
  toggleCompact: () => set((state) => ({ compact: !state.compact })),
}));
