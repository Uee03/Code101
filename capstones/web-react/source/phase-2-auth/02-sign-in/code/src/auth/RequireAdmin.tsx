import { useEffect, useRef } from 'react';
import { Outlet, useLocation } from 'react-router';
import { useAuth } from 'react-oidc-context';
import { useMe } from '../hooks/me';
import { config } from '../config';
export function RequireAdmin() {
  const me = useMe(); const auth = useAuth(); const location = useLocation(); const started = useRef(false);
  const admin = me.data?.roles.includes('admin'); const scoped = me.data?.scopes.includes('tasks:admin');
  useEffect(() => {
    if (admin && scoped) sessionStorage.removeItem('ts.stepup');
    if (admin && !scoped && !started.current && !sessionStorage.getItem('ts.stepup')) {
      started.current = true; sessionStorage.setItem('ts.stepup', '1');
      void auth.signinRedirect({ scope: `${config.scopes} tasks:admin`, prompt: 'none',
        state: { returnTo: location.pathname + location.search } });
    }
  }, [admin, scoped, auth, location.pathname, location.search]);
  if (me.isPending) return <p role="status">Checking access</p>;
  if (me.error) return <p role="alert">{me.error.message}</p>;
  if (!admin || !scoped) return <section><h1>You do not have access</h1><p>Admin role and tasks:admin scope are required.</p></section>;
  return <Outlet />;
}
