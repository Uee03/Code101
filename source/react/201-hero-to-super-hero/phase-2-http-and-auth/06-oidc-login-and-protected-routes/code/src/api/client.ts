import createClient from 'openapi-fetch';
import type { paths } from './schema';
import { config } from '../config';
import { authTransport } from '../auth/auth-middleware';

export const makeClient = (baseUrl: string, transport: typeof fetch = fetch) =>
  createClient<paths>({ baseUrl, fetch: transport });

export const api = makeClient(config.apiBaseUrl, authTransport(config.apiBaseUrl));
