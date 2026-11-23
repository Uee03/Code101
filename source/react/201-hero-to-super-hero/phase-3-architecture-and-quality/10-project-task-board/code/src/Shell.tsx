import { Suspense } from 'react';
import { NavLink, Outlet } from 'react-router';
import { useAuth } from 'react-oidc-context';
import { signOut } from './auth/user-manager';
import AppErrorBoundary from './shared/AppErrorBoundary';

export default function Shell() {
  const auth = useAuth();
  return (
    <>
      <a className="skip-link" href="#main">
        Skip to main content
      </a>
      <header>
        <nav aria-label="Main">
          <NavLink to="/" end>
            My teams
          </NavLink>
          {auth.isAuthenticated ? (
            <button type="button" onClick={() => void signOut()}>
              Sign out
            </button>
          ) : (
            <NavLink to="/login">Login</NavLink>
          )}
        </nav>
      </header>
      <main id="main" tabIndex={-1}>
        <AppErrorBoundary>
          <Suspense fallback={<p role="status">Loading page...</p>}>
            <Outlet />
          </Suspense>
        </AppErrorBoundary>
      </main>
    </>
  );
}
