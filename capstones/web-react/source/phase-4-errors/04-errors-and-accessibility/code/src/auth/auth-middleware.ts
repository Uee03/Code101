import { apiEvents, notify } from '../api/notices';
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
    const retry = request.clone(); const rateRetry = request.clone();
    let response: Response;
    try { response = await transport(request); }
    catch (error) { apiEvents.dispatchEvent(new Event('network-error')); throw error; }
    if (response.status === 401) {
      try {
        retry.headers.set('Authorization', `Bearer ${await renew()}`);
        response = await transport(retry);
      } catch { await endSession(); return response; }
      if (response.status === 401) await endSession();
    }
    if (response.status === 429) {
      const seconds = Math.max(0, Number(response.headers.get('Retry-After')) || 1);
      notify('Too many requests', seconds);
      if (request.method === 'GET') {
        await new Promise(resolve => setTimeout(resolve, seconds * 1000));
        const current = await getAccessToken();
        if (current) rateRetry.headers.set('Authorization', `Bearer ${current}`);
        response = await transport(rateRetry);
      }
    } else if (request.url !== `${base}/health` && response.headers.get('RateLimit-Remaining') === '0') {
      notify('Request budget exhausted. Wait before your next action.');
    }
    return response;
  };
}
