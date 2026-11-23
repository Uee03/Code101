import { AccessTokenEvents, InMemoryWebStorage, OidcClient, User } from 'oidc-client-ts';
import { oidcSettings } from '../src/auth/oidc-config';
const { settings, memory } = oidcSettings('http://localhost:5173', new InMemoryWebStorage());
if (!(memory instanceof InMemoryWebStorage)) throw new Error('Expected memory user storage');
await settings.userStore!.set('smoke', 'memory-only');
if (memory.getItem('oidc.smoke') !== 'memory-only') throw new Error('Store was not backed by memory');
await settings.userStore!.remove('smoke');
const request = await new OidcClient(settings).createSigninRequest({
  redirect_uri: settings.redirect_uri, response_type: 'code', scope: settings.scope!,
});
const url = new URL(request.url);
if (url.searchParams.get('code_challenge_method') !== 'S256') throw new Error('PKCE missing');
const response = await fetch(url, { redirect: 'manual' });
if (response.status !== 200) throw new Error(`Login page ${response.status}`);
console.log('PKCE: S256; login page: 200; user store: memory');
// Demonstrate the library event without signing in or renewing a fake token.
const events = new AccessTokenEvents({ expiringNotificationTimeInSeconds: 1 });
let fired = false;
events.addAccessTokenExpiring(() => { fired = true; });
await events.load(new User({ access_token: 'not-a-real-token', token_type: 'Bearer',
  profile: { sub: 'smoke', iss: settings.authority, aud: settings.client_id, exp: 0, iat: 0 },
  expires_at: Math.floor(Date.now() / 1000) + 2 }));
await new Promise(resolve => setTimeout(resolve, 2100)); await events.unload();
if (!fired) throw new Error('Expiry event did not fire');
console.log('expiry event: fired without automaticSilentRenew');
