import { Navigate, Outlet, useLocation } from 'react-router';
import { useAuth } from 'react-oidc-context';

export default function RequireAuth() {
  const auth = useAuth();
  const location = useLocation();
  if (auth.isLoading || auth.activeNavigator) {
    return <p role="status">Signing you in</p>;
  }
  if (!auth.isAuthenticated) {
    return <Navigate replace to={`/login?returnUrl=${encodeURIComponent(location.pathname + location.search)}`} />;
  }
  return <Outlet />;
}
