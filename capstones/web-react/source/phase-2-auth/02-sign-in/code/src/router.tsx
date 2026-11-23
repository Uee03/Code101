import { createBrowserRouter, Link, Outlet } from 'react-router';
import { RequireAuth } from './auth/RequireAuth';
import { RequireAdmin } from './auth/RequireAdmin';
import { signOut } from './auth/user-manager';
function Shell() {
  return <><header><nav aria-label="Main"><Link to="/">Dashboard</Link> <Link to="/admin/audit">Audit log</Link>
    <button onClick={() => void signOut()}>Sign out</button></nav></header><main><Outlet /></main></>;
}
export const router = createBrowserRouter([
  { element: <Shell />, children: [
    { path: '/login', lazy: () => import('./pages/Login') },
    { path: '/auth/callback', lazy: () => import('./pages/Callback') },
    { element: <RequireAuth />, children: [
      { index: true, lazy: () => import('./pages/Dashboard') },
      { element: <RequireAdmin />, children: [{ path: '/admin/audit', lazy: () => import('./pages/Audit') }] },
    ] },
    { path: '*', lazy: () => import('./pages/NotFound') },
  ] },
]);
