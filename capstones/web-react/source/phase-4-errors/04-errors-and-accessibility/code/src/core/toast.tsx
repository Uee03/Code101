import { createContext, useContext, useState, type ReactNode } from 'react';
const ToastContext = createContext<(text: string) => void>(() => {});
export const useToast = () => useContext(ToastContext);
export function ToastProvider({ children }: { children: ReactNode }) {
  const [message, setMessage] = useState('');
  return <ToastContext value={setMessage}>{children}<p className="toast" role="status" aria-live="polite">{message}</p></ToastContext>;
}
