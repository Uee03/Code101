import { useMe } from '../hooks/me';
export function Component() {
  const me = useMe();
  return <section><h1>Dashboard</h1><p role="status">{me.data ? `Hello, ${me.data.displayName}` : 'Loading caller'}</p>
    {me.error && <p role="alert">{me.error.message}</p>}
    <p>Roles: {me.data?.roles.join(', ')}</p><p>Scopes: {me.data?.scopes.join(', ')}</p>
  </section>;
}
