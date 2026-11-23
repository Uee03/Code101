import { create } from 'zustand';

type UiState = {
  query: string;
  toast: string | null;
  setQuery: (query: string) => void;
  showToast: (message: string) => void;
  clearToast: () => void;
  // TODO 1: add compact: boolean (start false) and toggleCompact: () => void.
};

export const useUiStore = create<UiState>()((set) => ({
  query: '',
  toast: null,
  setQuery: (query) => set({ query }),
  showToast: (message) => set({ toast: message }),
  clearToast: () => set({ toast: null }),
  // TODO 2: implement compact and toggleCompact (set receives the old state when you pass a function).
}));
