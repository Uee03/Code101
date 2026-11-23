import { NavLink, Outlet } from 'react-router';
import { BooksProvider } from './BooksContext';
import Header from './components/Header';
import Footer from './components/Footer';

export default function App() {
  return (
    <BooksProvider>
      <Header />
      <nav className="nav" aria-label="Main">
        <NavLink to="/" end>
          Books
        </NavLink>
        <NavLink to="/about">About</NavLink>
      </nav>
      <main>
        <Outlet />
      </main>
      <Footer />
    </BooksProvider>
  );
}
