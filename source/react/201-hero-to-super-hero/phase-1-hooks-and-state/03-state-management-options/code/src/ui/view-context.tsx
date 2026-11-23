import { createContext, useContext, useMemo, useState, type ReactNode } from 'react';

export type View = 'board' | 'list';

type ViewValue = {
  view: View;
  setView: (view: View) => void;
};

const ViewContext = createContext<ViewValue | null>(null);

export function ViewProvider({ children }: { children: ReactNode }) {
  const [view, setView] = useState<View>('board');
  const value = useMemo(() => ({ view, setView }), [view]);
  return <ViewContext value={value}>{children}</ViewContext>;
}

export function useView(): ViewValue {
  const value = useContext(ViewContext);
  if (!value) {
    throw new Error('useView must be used inside ViewProvider');
  }
  return value;
}
