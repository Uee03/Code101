import { Notice } from './shared/Notice';
import { createBrowserRouter, Link, Outlet } from 'react-router';
import { useAuth } from 'react-oidc-context';
import { RequireAuth } from './auth/RequireAuth';
import { RequireAdmin } from './auth/RequireAdmin';
import { signOut } from './auth/user-manager';
import { useMe } from './hooks/me';
import { Icon } from './shared/Icon';
import { useOnline, tryOnline } from './core/connectivity';
function UserMenu() {
  const me = useMe();
  return <><Link to="/teams"><Icon name="users" />Teams</Link>
    {me.data?.roles.includes('admin') && <Link to="/admin/audit">Audit log</Link>}
    <details><summary>{me.data?.displayName ?? 'User menu'}</summary>
      <button onClick={() => void signOut()}><Icon name="log-out" />Sign out</button></details></>;
}
function Shell() {
  const auth = useAuth(); const online = useOnline();
  return <><a className="skip" href="#content">Skip to content</a>
    <header><nav aria-label="Main"><Link to="/">Dashboard</Link>{auth.isAuthenticated ? <UserMenu /> : <Link to="/login">Login</Link>}</nav></header>
    {!online && <p role="alert"><Icon name="cloud-off" />You are offline. Writes are disabled. <button onClick={tryOnline}>Try again</button></p>}
    <Notice /><main id="content" tabIndex={-1}><Outlet /></main></>;
}
export const router = createBrowserRouter([
  { element: <Shell />, children: [
    { path: '/login', lazy: () => import('./pages/Login') },
    { path: '/auth/callback', lazy: () => import('./pages/Callback') },
    { element: <RequireAuth />, children: [
      { index: true, lazy: () => import('./pages/Dashboard') },
      { path: '/teams', lazy: () => import('./pages/Teams') },
      { path: '/teams/:teamId', lazy: () => import('./pages/TeamDetail') },
      { path: '/teams/:teamId/projects', lazy: () => import('./pages/Projects') },
      { path: '/projects/:projectId', lazy: () => import('./pages/Tasks') },
      { path: '/tasks/:taskId', lazy: () => import('./pages/TaskDetail') },
      { element: <RequireAdmin />, children: [{ path: '/admin/audit', lazy: () => import('./pages/Audit') }] },
    ] },
    { path: '*', lazy: () => import('./pages/NotFound') },
  ] },
]);
