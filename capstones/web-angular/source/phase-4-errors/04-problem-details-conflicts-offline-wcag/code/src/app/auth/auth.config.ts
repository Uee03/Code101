import { AuthConfig } from 'angular-oauth2-oidc';
import { environment } from '../../environments/environment';
export const storageRules = 'Tokens: memory only; nonce and PKCE_verifier: sessionStorage; ts.hint: non-secret localStorage flag';
export function authConfig(origin: string, admin = false): AuthConfig {
  return {
    issuer: environment.issuer,
    clientId: environment.clientId,
    redirectUri: origin + '/auth/callback',
    postLogoutRedirectUri: origin + '/login',
    responseType: 'code',
    scope: environment.scopes + (admin ? ' tasks:admin' : ''),
    requireHttps: 'remoteOnly',
    strictDiscoveryDocumentValidation: true,
    disablePKCE: false,
    timeoutFactor: 0.75,
    showDebugInformation: false,
    clearHashAfterLogin: true,
  };
}
export function safeReturn(value: string | null | undefined): string {
  return value?.startsWith('/') && !value.startsWith('//') && !/[\\\r\n]/.test(value) ? value : '/';
}
export function isApiUrl(value: string): boolean {
  const target = new URL(value, environment.apiBaseUrl);
  const base = new URL(environment.apiBaseUrl);
  const path = base.pathname.replace(/\/$/, '');
  return target.origin === base.origin && (target.pathname === path || target.pathname.startsWith(path + '/'));
}
