import { useHealth } from '../hooks/health';

export default function ApiStatus() {
  const health = useHealth();
  if (health.isPending) {
    return <p role="status">Checking the API...</p>;
  }
  if (health.isError) {
    return (
      <p role="alert">
        The API is not reachable. Is a backend running on port 8000? ({health.error.message})
      </p>
    );
  }
  return (
    <p role="status">
      API status: {health.data.status}
      {health.data.version ? `, version ${health.data.version}` : ''}
      {health.data.database ? `, database ${health.data.database}` : ''}
    </p>
  );
}
