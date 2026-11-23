import createClient, { type Middleware } from 'openapi-fetch';
import type { paths } from './schema.js';

export type FetchLike = (input: Request | URL | string) => Promise<Response>;

export interface ClientOptions {
  baseUrl: string;
  getToken: () => string | undefined;
  fetch?: FetchLike;
  onDeprecation?: (message: string) => void;
}

// The Sunset header is an HTTP date (RFC 8594). Show it as a plain date, or say it is unknown.
export function describeSunset(header: string | null): string {
  if (header === null) {
    return 'not announced';
  }
  const time = Date.parse(header);
  return Number.isNaN(time) ? 'unknown' : new Date(time).toISOString().slice(0, 10);
}

export function createTasksClient(options: ClientOptions) {
  const client = createClient<paths>({ baseUrl: options.baseUrl, fetch: options.fetch });

  const middleware: Middleware = {
    onRequest({ request }) {
      const token = options.getToken();
      if (token !== undefined) {
        request.headers.set('Authorization', `Bearer ${token}`);
      }
      request.headers.set('X-Request-Id', crypto.randomUUID());
      return request;
    },
    onResponse({ response }) {
      // A server announces retirement with the Deprecation and Sunset headers; surface it early.
      if (response.headers.has('Deprecation')) {
        options.onDeprecation?.(
          `Deprecated API in use. Sunset: ${describeSunset(response.headers.get('Sunset'))}`,
        );
      }
      return response;
    },
  };

  client.use(middleware);
  return client;
}

export type TasksClient = ReturnType<typeof createTasksClient>;
