import { Link } from 'react-router';
import { ApiProblem } from '../api/problem';
import { tryOnline } from '../core/connectivity';
import { Icon } from './Icon';
export function Banner({ error, retry }: { error: unknown; retry?: () => unknown }) {
  if (!error) return null;
  const problem = error instanceof ApiProblem ? error : undefined;
  const terminal = problem?.status === 403 || problem?.status === 404;
  return <section role="alert"><Icon name="alert-triangle" />
    {terminal && <h2>{problem?.status === 403 ? 'You do not have access' : 'Not found'}</h2>}
    <p>{error instanceof Error ? error.message : 'Request failed.'}</p>
    {problem?.traceId && <p>Support trace: {problem.traceId}</p>}
    {problem?.code === 'last_lead' && <p>Assign another lead before removing or demoting the last lead.</p>}
    {retry && !terminal && <button onClick={() => { tryOnline(); void retry(); }}><Icon name="refresh-cw" />Try again</button>}
    <Link to="/">Home</Link>
  </section>;
}
