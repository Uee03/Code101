import { Link } from 'react-router';

export default function NotFound() {
  return (
    <section>
      <h1>Not found</h1>
      <p>This page is not available.</p>
      <Link to="/">Home</Link>
    </section>
  );
}
