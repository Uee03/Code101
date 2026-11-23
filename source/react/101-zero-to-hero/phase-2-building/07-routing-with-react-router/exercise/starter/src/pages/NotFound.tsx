import { Link } from 'react-router';

export default function NotFound() {
  // TODO 1: import useLocation from 'react-router' and read the current address with it.
  return (
    <section>
      <h2>Page not found</h2>
      <p>There is nothing at this address.</p>
      {/* TODO 2: show the wrong address, for example: Nothing lives at /oops */}
      {/* TODO 3: add a button "Go back" that goes one step back in the history (useNavigate). */}
      <Link to="/">Back to the list</Link>
    </section>
  );
}
