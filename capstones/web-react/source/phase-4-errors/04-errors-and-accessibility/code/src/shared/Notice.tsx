import { useEffect, useState, useSyncExternalStore } from 'react';
import { apiEvents, getNotice } from '../api/notices';
export function Notice() {
  const notice = useSyncExternalStore(listener => {
    apiEvents.addEventListener('notice', listener); return () => apiEvents.removeEventListener('notice', listener);
  }, getNotice);
  const [now, setNow] = useState(Date.now());
  useEffect(() => { const id = setInterval(() => setNow(Date.now()), 1000); return () => clearInterval(id); }, []);
  const seconds = Math.max(0, Math.ceil((notice.until - now) / 1000));
  return <p role="status">{notice.message}{seconds > 0 ? `, retrying GET in ${seconds} s; writes need a manual retry` : ''}</p>;
}
