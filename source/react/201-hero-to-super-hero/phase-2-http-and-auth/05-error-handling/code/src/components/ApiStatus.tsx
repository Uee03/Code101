import { useHealth } from '../hooks/health';
import ProblemPanel from '../shared/ProblemPanel';

export default function ApiStatus() {
  const health = useHealth();
  if (health.isPending) {
    return <p role="status">Checking the API...</p>;
  }
  if (health.isError) {
    return <ProblemPanel error={health.error} onRetry={() => void health.refetch()} />;
  }
  return (
    <p role="status">
      API status: {health.data.status}
      {health.data.version ? `, version ${health.data.version}` : ''}
      {health.data.database ? `, database ${health.data.database}` : ''}
    </p>
  );
}
