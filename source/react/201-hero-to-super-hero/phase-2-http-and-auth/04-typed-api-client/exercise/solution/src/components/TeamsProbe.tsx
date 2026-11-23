import { useState } from 'react';
import { api } from '../api/client';

export default function TeamsProbe() {
  const [message, setMessage] = useState('Not called yet.');

  async function load() {
    setMessage('Calling...');
    try {
      const { data, error, response } = await api.GET('/v1/teams', {
        params: { query: { q: 'a', limit: 3, sort: '-createdAt' } },
      });
      if (data) {
        setMessage(`The API returned ${data.items.length} teams.`);
      } else {
        const trace = error?.traceId ? ` (trace ${error.traceId})` : '';
        setMessage(`The API answered ${response.status}: ${error?.title ?? 'no details'}${trace}`);
      }
    } catch {
      setMessage('The API is not reachable. Is a backend running on port 8000?');
    }
  }

  return (
    <section>
      <h2>Typed call to listTeams</h2>
      <p>This call needs a signed-in user. Without a token the API answers 401; signing in comes in lesson 06.</p>
      <button type="button" onClick={() => void load()}>
        Call GET /v1/teams
      </button>
      <p role="status">{message}</p>
    </section>
  );
}
