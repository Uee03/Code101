import { describe } from './exhaustive.js';
import type { CamelizeKeys, ParamArgs, PathParams, SnakeToCamel, Split } from './route-types.js';
import { href, matchRoute } from './routes.js';
import type { Equal, Expect } from './testing.js';

export type TypeTests = [
  Expect<Equal<Split<'a.b.c', '.'>, ['a', 'b', 'c']>>,
  Expect<Equal<PathParams<'/'>, never>>,
  Expect<Equal<PathParams<'/teams/:teamId'>, 'teamId'>>,
  Expect<Equal<PathParams<'/teams/:teamId/projects/:projectId'>, 'teamId' | 'projectId'>>,
  Expect<Equal<ParamArgs<'/teams'>, []>>,
  Expect<Equal<ParamArgs<'/teams/:teamId'>, [params: { teamId: string }]>>,
  Expect<Equal<SnakeToCamel<'due_date'>, 'dueDate'>>,
  Expect<Equal<CamelizeKeys<{ due_date: string; id: number }>, { dueDate: string; id: number }>>,
];

// Each directive must hide exactly one real error.
export function negativeTests(): void {
  href('home');
  href('team', { teamId: 't1' });
  // @ts-expect-error the team route needs its parameter
  href('team');
  // @ts-expect-error wrong parameter name
  href('team', { id: 't1' });
  // @ts-expect-error the home route takes no parameters
  href('home', { teamId: 'x' });
  // @ts-expect-error unknown route name
  href('settings');
  // @ts-expect-error projectId is missing
  href('project', { teamId: 't1' });
  // @ts-expect-error 'archived' is not a known event type
  describe({ type: 'archived', id: 'x' });

  const match = matchRoute('/tasks/t1');
  if (match?.name === 'task') {
    // Narrowing on name gives params the right shape.
    const id: string = match.params.taskId;
    void id;
  }
}
