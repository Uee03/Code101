import { useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import { makeClient } from '../api/client';
import { scenarios } from '../api/canned';
import { unwrap } from '../api/unwrap';
import ProblemPanel from '../shared/ProblemPanel';

const teamId = '9f0c1b0e-2d1a-4a5b-8f2c-6a1d3e5b7c90';

export default function Playground() {
  const [selected, setSelected] = useState(scenarios[0]?.id ?? 'ok');
  const run = useMutation({
    mutationFn: async (id: string) => {
      const scenario = scenarios.find((item) => item.id === id);
      if (!scenario) {
        throw new Error('Unknown scenario');
      }
      const client = makeClient('http://localhost:8000', scenario.transport);
      return unwrap(await client.GET('/v1/teams/{teamId}', { params: { path: { teamId } } }));
    },
  });

  return (
    <section>
      <h2>Simulated server answers</h2>
      <p>No backend is needed: each choice makes the client receive a canned response.</p>
      <label>
        Scenario{' '}
        <select value={selected} onChange={(event) => setSelected(event.target.value)}>
          {scenarios.map((scenario) => (
            <option key={scenario.id} value={scenario.id}>
              {scenario.label}
            </option>
          ))}
        </select>
      </label>{' '}
      <button type="button" onClick={() => run.mutate(selected)} disabled={run.isPending}>
        Run
      </button>
      {run.isPending && <p role="status">Calling...</p>}
      {run.isSuccess && <p role="status">Team found: {run.data.name}</p>}
      {run.isError && <ProblemPanel error={run.error} onRetry={() => run.mutate(selected)} />}
    </section>
  );
}
