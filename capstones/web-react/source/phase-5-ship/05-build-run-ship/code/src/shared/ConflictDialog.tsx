import { useEffect, useRef, useState } from 'react';
import type { Task, Schemas } from '../api/types';
import { useOnline } from '../core/connectivity';
import { Icon } from './Icon';
export function ConflictDialog({ server, local, useServer, apply }: {
  server: Task; local: Schemas['TaskUpdate']; useServer: () => void; apply: () => Promise<void>;
}) {
  const ref = useRef<HTMLDialogElement>(null); const online = useOnline(); const [error, setError] = useState(''); const [pending, setPending] = useState(false);
  useEffect(() => { const dialog = ref.current!; dialog.showModal(); return () => dialog.close(); }, []);
  return <dialog ref={ref} aria-labelledby="conflict-title"><h2 id="conflict-title"><Icon name="alert-triangle" />This task changed</h2>
    <p>Your draft is kept. Escape closes the dialog; submitting the draft again will reopen it if still stale.</p>
    <table><caption>Server and your changed fields</caption><thead><tr><th scope="col">Field</th><th scope="col">Server</th><th scope="col">Mine</th></tr></thead>
      <tbody>{Object.entries(local).map(([key, value]) => <tr key={key}><th scope="row">{key}</th>
        <td>{String(server[key as keyof Task] ?? '')}</td><td>{String(value ?? '')}</td></tr>)}</tbody></table>
    <p role="alert">{error}</p><button autoFocus onClick={useServer}>Use the server version</button>
    <button disabled={!online || pending} onClick={async () => {
      setPending(true); setError(''); try { await apply(); }
      catch (failure) { setError(failure instanceof Error ? failure.message : 'Could not apply.'); }
      finally { setPending(false); }
    }}>Apply my changes on top</button>
  </dialog>;
}
