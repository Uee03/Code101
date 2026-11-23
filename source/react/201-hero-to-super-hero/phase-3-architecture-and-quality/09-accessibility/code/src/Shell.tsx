import { NavLink, Outlet } from 'react-router';

export default function Shell() {
  return (
    <>
      <a className="skip-link" href="#main">
        Skip to main content
      </a>
      <header>
        <nav aria-label="Main">
          <NavLink to="/" end>
            Tasks
          </NavLink>
          <NavLink to="/help">Help</NavLink>
        </nav>
      </header>
      <main id="main" tabIndex={-1}>
        <Outlet />
      </main>
    </>
  );
}
