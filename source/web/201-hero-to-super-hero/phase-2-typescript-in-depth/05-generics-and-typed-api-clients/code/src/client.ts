export interface FetchResponse {
  readonly ok: boolean;
  readonly status: number;
  json(): Promise<unknown>;
}

export type FetchLike = (url: string, init?: { method?: string }) => Promise<FetchResponse>;

export interface ApiError {
  kind: "network" | "http" | "parse";
  message: string;
}

export type Result<T, E = ApiError> = { ok: true; value: T } | { ok: false; error: E };

export interface Endpoint<T> {
  readonly method: "GET" | "POST";
  readonly path: string;
  readonly parse: (data: unknown) => T;
}

export function endpoint<T>(
  method: "GET" | "POST",
  path: string,
  parse: (data: unknown) => T,
): Endpoint<T> {
  return { method, path, parse };
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

export class ApiClient {
  private readonly baseUrl: string;
  private readonly fetcher: FetchLike;

  constructor(baseUrl: string, fetcher: FetchLike) {
    this.baseUrl = baseUrl;
    this.fetcher = fetcher;
  }

  async request<T>(target: Endpoint<T>): Promise<Result<T>> {
    let response: FetchResponse;
    try {
      response = await this.fetcher(this.baseUrl + target.path, { method: target.method });
    } catch (error) {
      return { ok: false, error: { kind: "network", message: errorMessage(error) } };
    }
    if (!response.ok) {
      return { ok: false, error: { kind: "http", message: `HTTP ${response.status}` } };
    }
    try {
      const data: unknown = await response.json();
      return { ok: true, value: target.parse(data) };
    } catch (error) {
      return { ok: false, error: { kind: "parse", message: errorMessage(error) } };
    }
  }
}
