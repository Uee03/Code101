export const environment = {
  // false: no sign-in, run against `npm run mock`. true: sign in with Keycloak, run against `npm run mock:auth` or a platform backend.
  authEnabled: false,
  apiBaseUrl: 'http://localhost:8000',
  issuer: 'http://localhost:8180/realms/tasksteams',
  clientId: 'tasks-web',
  scopes: 'openid profile email tasks:read tasks:write'
};
