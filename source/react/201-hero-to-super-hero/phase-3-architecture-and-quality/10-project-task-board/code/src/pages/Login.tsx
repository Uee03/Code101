import { useEffect, useRef } from 'react';
import { Navigate, useSearchParams } from 'react-router';
import { useAuth } from 'react-oidc-context';
import { safeRoute } from '../auth/safe-route';

export default function Login() {
  const auth = useAuth();
  const [params] = useSearchParams();
  const started = useRef(false);
  const returnTo = safeRoute(params.get('returnUrl'));

  useEffect(() => {
    if (auth.error) {
      localStorage.removeItem('ts.hint');
      history.replaceState({}, '', '/login');
    }
    const canTryQuietly =
      !auth.isLoading && !auth.isAuthenticated && !auth.error && !started.current && localStorage.getItem('ts.hint');
    if (canTryQuietly) {
      started.current = true;
      void auth.signinRedirect({ prompt: 'none', state: { returnTo } });
    }
  }, [auth, returnTo]);

  if (auth.isAuthenticated) {
    return <Navigate replace to={returnTo} />;
  }
  return (
    <section>
      <h1>Login</h1>
      <p>Sign in with the Tasks and Teams Keycloak realm.</p>
      {auth.error && <p role="alert">{auth.error.message}</p>}
      <button
        type="button"
        disabled={auth.isLoading || !!auth.activeNavigator}
        onClick={() => {
          localStorage.removeItem('ts.hint');
          void auth.signinRedirect({ state: { returnTo } });
        }}
      >
        Sign in
      </button>
    </section>
  );
}
