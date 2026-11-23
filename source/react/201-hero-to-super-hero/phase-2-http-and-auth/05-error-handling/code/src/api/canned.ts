export type Scenario = {
  id: string;
  label: string;
  transport: typeof fetch;
};

function respond(status: number, body: unknown, headers: Record<string, string> = {}): typeof fetch {
  return async () =>
    new Response(JSON.stringify(body), {
      status,
      headers: { 'Content-Type': status >= 400 ? 'application/problem+json' : 'application/json', ...headers },
    });
}

const team = {
  id: '9f0c1b0e-2d1a-4a5b-8f2c-6a1d3e5b7c90',
  name: 'Platform team',
  description: 'Keeps the platform running.',
  memberCount: 3,
  createdBy: '2f4b7d1e-5c3a-4e8f-9a6b-1d2c3e4f5a6b',
  version: 1,
  createdAt: '2026-01-01T09:00:00Z',
  updatedAt: '2026-01-01T09:00:00Z',
};

const traceId = '4bf92f3577b34da6a3ce929d0e0e4736';

export const scenarios: Scenario[] = [
  { id: 'ok', label: '200 team found', transport: respond(200, team) },
  {
    id: '404',
    label: '404 not found',
    transport: respond(404, {
      type: 'https://code101.example/problems/not-found',
      title: 'Not found',
      status: 404,
      detail: 'No team with this id.',
      traceId,
    }),
  },
  {
    id: '409',
    label: '409 last lead',
    transport: respond(409, {
      type: 'https://code101.example/problems/conflict',
      title: 'Conflict',
      status: 409,
      detail: 'A team must keep at least one lead.',
      code: 'last_lead',
      traceId,
    }),
  },
  {
    id: '422',
    label: '422 validation',
    transport: respond(422, {
      type: 'https://code101.example/problems/validation-error',
      title: 'Validation failed',
      status: 422,
      detail: 'One or more fields are invalid.',
      traceId,
      errors: [{ pointer: '/name', detail: 'Name is required.' }],
    }),
  },
  {
    id: '429',
    label: '429 too many requests',
    transport: respond(
      429,
      { type: 'https://code101.example/problems/rate-limited', title: 'Too many requests', status: 429, traceId },
      { 'Retry-After': '7' },
    ),
  },
  {
    id: '500',
    label: '500 server error',
    transport: respond(500, {
      type: 'https://code101.example/problems/internal',
      title: 'Internal server error',
      status: 500,
      traceId,
    }),
  },
  {
    id: 'network',
    label: 'Network failure',
    transport: async () => {
      throw new TypeError('Failed to fetch');
    },
  },
];
