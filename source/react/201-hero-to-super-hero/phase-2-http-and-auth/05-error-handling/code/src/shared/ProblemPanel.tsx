import { ApiProblem } from '../api/problem';
import { describeError } from '../api/describe';

type ProblemPanelProps = {
  error: unknown;
  onRetry?: () => void;
};

export default function ProblemPanel({ error, onRetry }: ProblemPanelProps) {
  const view = describeError(error);
  const traceId = error instanceof ApiProblem ? error.traceId : undefined;
  return (
    <section role="alert" className="problem">
      <h2>{view.heading}</h2>
      <p>{view.message}</p>
      {view.details.length > 0 && (
        <ul>
          {view.details.map((line) => (
            <li key={line}>{line}</li>
          ))}
        </ul>
      )}
      {traceId && <p>Support code: {traceId}</p>}
      {view.retryable && onRetry && (
        <button type="button" onClick={onRetry}>
          Try again
        </button>
      )}
    </section>
  );
}
