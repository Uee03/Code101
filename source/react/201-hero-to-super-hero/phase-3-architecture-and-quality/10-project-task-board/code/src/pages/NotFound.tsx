import { Link } from 'react-router';
import PageTitle from '../core/PageTitle';

export default function NotFound() {
  return (
    <>
      <PageTitle>Not found</PageTitle>
      <p>This page is not available.</p>
      <Link to="/">Back to my teams</Link>
    </>
  );
}
