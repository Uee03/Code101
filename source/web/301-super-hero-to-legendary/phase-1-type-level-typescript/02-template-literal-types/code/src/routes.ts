import type { ParamArgs, PathParams } from './route-types.js';

// "as const" keeps the exact strings; "satisfies" checks the shape without widening them.
export const routes = {
  home: '/',
  teams: '/teams',
  team: '/teams/:teamId',
  project: '/teams/:teamId/projects/:projectId',
  task: '/tasks/:taskId',
} as const satisfies Record<string, `/${string}`>;

export type Routes = typeof routes;
export type RouteName = keyof Routes;

// One union member per route: the params type depends on the route name.
export type Match = {
  [N in RouteName]: { name: N; params: Record<PathParams<Routes[N]>, string> };
}[RouteName];

const PARAM = /:([A-Za-z0-9_]+)/g;

export function href<N extends RouteName>(name: N, ...args: ParamArgs<Routes[N]>): string {
  // Boundary cast: TypeScript cannot index a rest tuple that depends on N.
  const params = (args as unknown as [Readonly<Record<string, string>>?])[0] ?? {};
  return routes[name].replace(PARAM, (_match, key: string) => {
    const value = params[key];
    if (value === undefined) {
      throw new Error(`Missing route param: ${key}`);
    }
    return encodeURIComponent(value);
  });
}

const patterns = (Object.keys(routes) as RouteName[]).map((name) => ({
  name,
  regex: new RegExp(`^${routes[name].replace(PARAM, '(?<$1>[^/]+)')}$`),
}));

function decode(value: string): string | undefined {
  try {
    return decodeURIComponent(value);
  } catch {
    return undefined;
  }
}

export function matchRoute(pathname: string): Match | undefined {
  for (const { name, regex } of patterns) {
    const found = regex.exec(pathname);
    if (!found) {
      continue;
    }
    const params: Record<string, string> = {};
    for (const [key, raw] of Object.entries(found.groups ?? {})) {
      const value = decode(raw);
      if (value === undefined) {
        return undefined;
      }
      params[key] = value;
    }
    return { name, params } as Match;
  }
  return undefined;
}
