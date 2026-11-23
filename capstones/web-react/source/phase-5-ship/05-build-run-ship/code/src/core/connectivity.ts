import { useSyncExternalStore } from 'react';
import { onlineManager } from '@tanstack/react-query';
import { apiEvents } from '../api/notices';
onlineManager.setEventListener(setOnline => {
  const online = () => setOnline(true); const offline = () => setOnline(false);
  window.addEventListener('online', online); window.addEventListener('offline', offline);
  apiEvents.addEventListener('network-error', offline);
  return () => {
    window.removeEventListener('online', online); window.removeEventListener('offline', offline);
    apiEvents.removeEventListener('network-error', offline);
  };
});
export function useOnline() {
  return useSyncExternalStore(onlineManager.subscribe.bind(onlineManager), () => onlineManager.isOnline(), () => true);
}
export function tryOnline() { onlineManager.setOnline(navigator.onLine); }
