import { useQuery } from '@tanstack/react-query';
import { api } from '../api/client';
import { unwrap } from '../api/unwrap';
export function Component() {
  const audit = useQuery({ queryKey: ['audit'], queryFn: async () => unwrap(await api.GET('/v1/audit-log')), retry: false });
  return <section><h1>Audit log</h1>{audit.error && <p role="alert">{audit.error.message}</p>}
    <ul>{audit.data?.items.map(entry => <li key={entry.id}>{entry.action} {entry.entityType}</li>)}</ul>
  </section>;
}
