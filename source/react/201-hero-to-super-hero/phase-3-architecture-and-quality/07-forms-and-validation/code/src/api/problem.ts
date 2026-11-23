export class ApiProblem extends Error {
  type = 'about:blank';
  title = 'Request failed';
  status = 0;
  detail?: string;
  instance?: string;
  traceId?: string;
  code?: string;
  errors?: { pointer: string; detail: string }[];
  retryAfter?: number;

  constructor(values: Partial<ApiProblem>) {
    super(values.detail ?? values.title ?? 'Request failed');
    Object.assign(this, values);
    this.name = 'ApiProblem';
  }
}

export function parseProblem(response: Response, body: unknown): ApiProblem {
  const isProblem =
    response.headers.get('Content-Type')?.includes('application/problem+json') && body && typeof body === 'object';
  const fields = isProblem ? (body as Partial<ApiProblem>) : {};
  const retry = Number(response.headers.get('Retry-After'));
  return new ApiProblem({
    ...fields,
    status: response.status,
    title: fields.title ?? `Request failed (${response.status})`,
    retryAfter: response.headers.has('Retry-After') && Number.isFinite(retry) ? Math.max(0, retry) : undefined,
  });
}
