import { Link, useLocation, useNavigate } from 'react-router';

export default function NotFound() {
  const location = useLocation();
  const navigate = useNavigate();
  return (
    <section>
      <h2>Page not found</h2>
      <p>Nothing lives at {location.pathname}</p>
      <button type="button" onClick={() => navigate(-1)}>
        Go back
      </button>
      <Link to="/">Back to the list</Link>
    </section>
  );
}
