import { create } from 'zustand';

type UiState = {
  query: string;
  toast: string | null;
  setQuery: (query: string) => void;
  showToast: (message: string) => void;
  clearToast: () => void;
};

export const useUiStore = create<UiState>()((set) => ({
  query: '',
  toast: null,
  setQuery: (query) => set({ query }),
  showToast: (message) => set({ toast: message }),
  clearToast: () => set({ toast: null }),
}));
