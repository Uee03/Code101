import { Link } from 'react-router';
import { Icon } from './Icon';
export function Banner({ error, retry }: { error: unknown; retry?: () => unknown }) {
  if (!error) return null;
  return <section role="alert"><Icon name="alert-triangle" /> {error instanceof Error ? error.message : 'Request failed.'}
    {retry && <button onClick={() => void retry()}><Icon name="refresh-cw" />Try again</button>}
    <Link to="/">Home</Link>
  </section>;
}
