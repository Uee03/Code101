import { readFileSync, writeFileSync } from 'node:fs';
const file = 'src/environments/environment.ts';
const current = JSON.parse(readFileSync(file, 'utf8').replace('export const environment = ', '').replace(/;\s*$/, ''));
for (const [key, variable] of Object.entries({ apiBaseUrl: 'API_BASE_URL', issuer: 'OIDC_ISSUER', clientId: 'OIDC_CLIENT_ID' })) {
  if (process.env[variable]) current[key] = process.env[variable];
}
writeFileSync(file, 'export const environment = ' + JSON.stringify(current, null, 2) + ';\n');
console.log('Public build configuration written (no secrets)');
