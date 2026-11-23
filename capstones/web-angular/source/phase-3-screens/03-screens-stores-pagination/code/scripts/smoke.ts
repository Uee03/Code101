import '@angular/compiler';
import { authSmoke } from './smoke-auth';
import { HttpErrorResponse } from '@angular/common/http';
import { nodeClient } from './node-client';
import { environment } from '../src/environments/environment';
import { listTeams, listTasks } from '../src/app/api/functions';
import { getHealth } from '../src/app/api/fn/platform/get-health';
import { getMe } from '../src/app/api/fn/platform/get-me';
async function main() {
  await authSmoke();
  const anonymous = nodeClient();
  try { await anonymous.api.invoke(getMe); throw new Error('Expected anonymous 401'); }
  catch (error) {
    if (!(error instanceof HttpErrorResponse) || error.status !== 401) throw error;
    console.log(`Anonymous request: ${error.status} ${error.error.title}`);
    console.log(`Anonymous detail: ${error.error.detail}`);
  } finally { anonymous.close(); }
  const discovery = await fetch(environment.issuer + '/.well-known/openid-configuration').then(r => r.json());
  const response = await fetch(discovery.token_endpoint, {
    method: 'POST', body: new URLSearchParams({ client_id: 'tasks-smoke', grant_type: 'password',
      username: 'alice', password: process.env['SMOKE_ALICE_PASSWORD'] ?? 'alice-local-fake',
      scope: 'openid profile email tasks:read tasks:write tasks:admin' }),
  });
  if (!response.ok) throw new Error(`Smoke token request: ${response.status}`);
  const { access_token } = await response.json();
  const client = nodeClient(access_token);
  try {
    const health = await client.api.invoke(getHealth);
    const me = await client.api.invoke(getMe);
    console.log(`health: ${health.status}`);
    console.log(`me: ${me.username} (${me.roles.join(', ')})`);
    let cursor: string | undefined;
    let teams = 0;
    do {
      const page = await client.api.invoke(listTeams, { limit: 1, cursor });
      teams += page.items.length; cursor = page.page.nextCursor ?? undefined;
    } while (cursor);
    console.log(`teams: ${teams}`);
    let tasks = 0;
    do {
      const page = await client.api.invoke(listTasks, { projectId: '9a000000-0000-4000-8000-000000000001', limit: 2, cursor });
      console.log(`tasks page: ${page.items.length}`);
      tasks += page.items.length; cursor = page.page.nextCursor ?? undefined;
    } while (cursor);
    console.log(`tasks: ${tasks}; nextCursor: null`);
  } finally { client.close(); }
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
