import { Icon } from '../shared/Icon';
import { Page } from '../shared/Page';
import { useEffect, useRef } from 'react';
import { useAuth } from 'react-oidc-context';
import { Link, Navigate, useSearchParams } from 'react-router';
import { safeRoute } from '../auth/safe-route';
export function Component() {
  const auth = useAuth(); const [params] = useSearchParams(); const started = useRef(false);
  const returnTo = safeRoute(params.get('returnUrl'));
  useEffect(() => {
    if (auth.error) { localStorage.removeItem('ts.hint'); history.replaceState({}, '', '/login'); }
    if (!auth.isLoading && !auth.isAuthenticated && !auth.error && !started.current && localStorage.getItem('ts.hint')) {
      started.current = true;
      void auth.signinRedirect({ prompt: 'none', state: { returnTo } });
    }
  }, [auth, returnTo]);
  if (auth.isAuthenticated) return <Navigate replace to={returnTo} />;
  return <Page title="Login"><p>Sign in with the Tasks and Teams Keycloak realm.</p>
    {auth.error && <p role="alert">{auth.error.message}</p>}
    <button disabled={auth.isLoading || !!auth.activeNavigator} onClick={() => {
      localStorage.removeItem('ts.hint'); void auth.signinRedirect({ state: { returnTo } });
    }}><Icon name="log-in" />Sign in</button><p><Link to="/">Home</Link></p>
  </Page>;
}
