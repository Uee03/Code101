import { Link } from 'react-router';
import usePageTitle from '../hooks/usePageTitle';

export default function NotFound() {
  usePageTitle('Page not found - Reading list');
  return (
    <section>
      <h2>Page not found</h2>
      <p>There is nothing at this address.</p>
      <Link to="/">Back to the list</Link>
    </section>
  );
}
