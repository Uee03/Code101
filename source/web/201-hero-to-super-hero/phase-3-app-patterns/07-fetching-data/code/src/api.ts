import { httpMessage } from "./messages";

export interface ApiError {
  kind: "network" | "http" | "parse" | "aborted" | "timeout";
  message: string;
}

export type Result<T> = { ok: true; value: T } | { ok: false; error: ApiError };

export type Fetcher = (input: string, init?: RequestInit) => Promise<Response>;

export interface RequestOptions {
  fetcher?: Fetcher;
  signal?: AbortSignal;
  timeoutMs?: number;
}

function classify(error: unknown): ApiError {
  if (error instanceof DOMException && error.name === "AbortError") {
    return { kind: "aborted", message: "Request cancelled" };
  }
  if (error instanceof DOMException && error.name === "TimeoutError") {
    return { kind: "timeout", message: "The server took too long to answer" };
  }
  return { kind: "network", message: error instanceof Error ? error.message : "Network error" };
}

export async function getJson<T>(
  url: string,
  parse: (data: unknown) => T,
  options: RequestOptions = {},
): Promise<Result<T>> {
  const fetcher: Fetcher = options.fetcher ?? fetch;
  const signals: AbortSignal[] = [AbortSignal.timeout(options.timeoutMs ?? 8000)];
  if (options.signal) {
    signals.push(options.signal);
  }
  const signal = AbortSignal.any(signals);

  let response: Response;
  try {
    response = await fetcher(url, { signal, headers: { Accept: "application/json" } });
  } catch (error) {
    return { ok: false, error: classify(error) };
  }
  if (!response.ok) {
    return { ok: false, error: { kind: "http", message: httpMessage(response.status) } };
  }
  try {
    const data: unknown = await response.json();
    return { ok: true, value: parse(data) };
  } catch (error) {
    if (error instanceof DOMException) {
      return { ok: false, error: classify(error) };
    }
    const message = error instanceof Error ? error.message : "Unreadable response";
    return { ok: false, error: { kind: "parse", message } };
  }
}
