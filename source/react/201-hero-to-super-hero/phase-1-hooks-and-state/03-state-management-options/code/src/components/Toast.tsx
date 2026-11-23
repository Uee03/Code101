import { useEffect } from 'react';
import { useUiStore } from '../ui/ui-store';

export default function Toast() {
  const toast = useUiStore((state) => state.toast);
  const clearToast = useUiStore((state) => state.clearToast);

  useEffect(() => {
    if (toast === null) {
      return;
    }
    const timer = setTimeout(clearToast, 3000);
    return () => clearTimeout(timer);
  }, [toast, clearToast]);

  console.log('render Toast');
  return (
    <p role="status" className="toast">
      {toast ?? ''}
    </p>
  );
}
