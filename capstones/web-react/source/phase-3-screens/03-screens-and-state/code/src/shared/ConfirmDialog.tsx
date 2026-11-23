import { useRef, useState } from 'react';
import { useOnline } from '../core/connectivity';
import { Icon } from './Icon';
export function ConfirmDialog({ label, action }: { label: string; action: () => Promise<unknown> }) {
  const dialog = useRef<HTMLDialogElement>(null); const cancel = useRef<HTMLButtonElement>(null);
  const online = useOnline(); const [pending, setPending] = useState(false); const [error, setError] = useState('');
  return <><button disabled={!online || pending} onClick={() => { dialog.current?.showModal(); cancel.current?.focus(); }}>{label}</button>
    <dialog ref={dialog} aria-label={label}><p>{label}? This cannot be undone.</p><p role="alert">{error}</p>
      <button ref={cancel} onClick={() => dialog.current?.close()}><Icon name="x" />Cancel</button>
      <button disabled={!online || pending} onClick={async () => {
        setPending(true); setError('');
        try { await action(); dialog.current?.close(); } catch (failure) { setError(failure instanceof Error ? failure.message : 'Request failed.'); }
        finally { setPending(false); }
      }}>Confirm</button>
    </dialog></>;
}
