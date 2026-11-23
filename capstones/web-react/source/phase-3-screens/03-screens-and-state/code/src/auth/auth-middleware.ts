import { endSession, getAccessToken, renew } from './token-gate';
export function isApiUrl(url: string, base: string) {
  const target = new URL(url); const allowed = new URL(base);
  const prefix = allowed.pathname.replace(/\/$/, '');
  return target.origin === allowed.origin && (target.pathname === prefix || target.pathname.startsWith(`${prefix}/`));
}
export function authTransport(base: string, transport: typeof fetch = fetch): typeof fetch {
  return async (input, init) => {
    const request = new Request(input, init);
    if (!isApiUrl(request.url, base)) {
      request.headers.delete('Authorization');
      return transport(request);
    }
    const token = await getAccessToken();
    if (token) request.headers.set('Authorization', `Bearer ${token}`);
    const retry = request.clone();
    let response = await transport(request);
    if (response.status === 401) {
      try {
        retry.headers.set('Authorization', `Bearer ${await renew()}`);
        response = await transport(retry);
      } catch { await endSession(); return response; }
      if (response.status === 401) await endSession();
    }
    return response;
  };
}
