import { Page } from '../shared/Page';
import { useEffect } from 'react';
import { useAuth } from 'react-oidc-context';
import { Link, useNavigate } from 'react-router';
import { callbackReturn } from '../auth/user-manager';
export function Component() {
  const auth = useAuth(); const navigate = useNavigate();
  useEffect(() => {
    if (auth.isAuthenticated) void navigate(callbackReturn, { replace: true });
    if (auth.error) { localStorage.removeItem('ts.hint'); history.replaceState({}, '', '/auth/callback'); }
  }, [auth.isAuthenticated, auth.error, navigate]);
  return <Page title="Callback">{auth.error
    ? <><p role="alert">{auth.error.message}</p><Link to="/login">Return to Login</Link></>
    : <p role="status">Signing you in</p>}</Page>;
}
