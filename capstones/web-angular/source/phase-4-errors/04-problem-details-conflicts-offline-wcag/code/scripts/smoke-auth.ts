import { nodeClient } from './node-client';
import { DOCUMENT } from '@angular/common';
import { OAuthService, OAuthStorage, provideOAuthClient } from 'angular-oauth2-oidc';
import { authConfig, isApiUrl, safeReturn, storageRules } from '../src/app/auth/auth.config';
import { SplitStorage } from '../src/app/auth/split-storage';
export async function authSmoke() {
  const values = new Map<string, string>();
  Object.assign(globalThis, { self: globalThis, sessionStorage: {
    getItem: (key: string) => values.get(key) ?? null,
    setItem: (key: string, value: string) => values.set(key, value),
    removeItem: (key: string) => values.delete(key),
  } });
  const storage = new SplitStorage();
  const client = nodeClient('', [provideOAuthClient(), { provide: OAuthStorage, useValue: storage },
    { provide: DOCUMENT, useValue: { getElementById: () => null } }]);
  try {
    const oauth = client.injector.get(OAuthService);
    let open: (url: string) => void = () => {};
    oauth.configure({ ...authConfig('http://localhost:4200'), openUri: url => open(url) });
    await oauth.loadDiscoveryDocument();
    const url = new URL(await new Promise<string>(resolve => { open = resolve; oauth.initCodeFlow(); }));
    if (url.searchParams.get('code_challenge_method') !== 'S256') throw new Error('Missing S256');
    const response = await fetch(url);
    if (response.status !== 200 || !(await response.text()).includes('username')) throw new Error('Login page missing');
    storage.setItem('access_token', 'stand-in');
    if (values.has('access_token') || !values.has('PKCE_verifier')) throw new Error('Storage routing failed');
    if (isApiUrl('https://example.invalid/v1/me') || safeReturn('//evil.invalid') !== '/') throw new Error('URL boundary failed');
    console.log('authorization: code_challenge_method=S256; login page: 200');
    console.log(storageRules);
    console.log('Bearer host boundary and returnUrl: checked');
    storage.clear();
  } finally { client.close(); }
}
