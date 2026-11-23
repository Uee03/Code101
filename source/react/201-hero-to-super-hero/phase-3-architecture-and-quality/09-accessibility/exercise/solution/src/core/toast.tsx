import { createContext, useCallback, useContext, useMemo, useRef, useState, type ReactNode } from 'react';
import Icon from '../shared/Icon';

type ToastKind = 'status' | 'error';

type ToastApi = {
  show: (message: string, kind?: ToastKind) => void;
};

const ToastContext = createContext<ToastApi | null>(null);

export function ToastProvider({ children }: { children: ReactNode }) {
  const [messages, setMessages] = useState({ status: '', error: '' });
  const timer = useRef<number | undefined>(undefined);

  const show = useCallback((text: string, kind: ToastKind = 'status') => {
    window.clearTimeout(timer.current);
    setMessages({ status: kind === 'status' ? text : '', error: kind === 'error' ? text : '' });
    if (kind === 'status') {
      timer.current = window.setTimeout(() => setMessages({ status: '', error: '' }), 6000);
    }
  }, []);
  const api = useMemo(() => ({ show }), [show]);

  return (
    <ToastContext.Provider value={api}>
      {children}
      <div role="status" className="toast-region">
        {messages.status && (
          <p className="toast">
            <Icon name="check-circle" />
            {messages.status}
          </p>
        )}
      </div>
      <div role="alert" className="toast-region">
        {messages.error && <p className="toast">{messages.error}</p>}
      </div>
    </ToastContext.Provider>
  );
}

export function useToast(): ToastApi {
  const value = useContext(ToastContext);
  if (!value) {
    throw new Error('useToast must be used inside ToastProvider');
  }
  return value;
}
