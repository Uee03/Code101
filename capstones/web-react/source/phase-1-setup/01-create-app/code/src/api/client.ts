import createClient from 'openapi-fetch';
import type { paths } from './schema';
import { config } from '../config';
export const makeClient = (baseUrl: string, transport: typeof fetch = fetch) =>
  createClient<paths>({ baseUrl, fetch: transport });
export const api = makeClient(config.apiBaseUrl);
