import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { QueryClient, QueryClientProvider, useQuery } from '@tanstack/react-query';
import { api } from './api/client';
import { unwrap } from './api/unwrap';
import './styles.css';
function App() {
  const health = useQuery({ queryKey: ['health'], queryFn: async () => unwrap(await api.GET('/health')), retry: false });
  return <main><h1>Tasks and Teams</h1><p>Generated client ready.</p>
    <p role="status">API: {health.data?.status ?? (health.error ? health.error.message : 'checking')}</p>
    {health.error && <button onClick={() => void health.refetch()}>Try again</button>}
  </main>;
}
const queryClient = new QueryClient();
createRoot(document.getElementById('root')!).render(
  <StrictMode><QueryClientProvider client={queryClient}><App /></QueryClientProvider></StrictMode>,
);
