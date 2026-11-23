import { useInfiniteQuery } from '@tanstack/react-query';
import type { operations } from '../api/schema';
import { api } from '../api/client';
import { unwrap } from '../api/unwrap';
import { keys } from './keys';
export type AuditFilter = NonNullable<operations['listAuditLog']['parameters']['query']>;
export function useAudit(filters: AuditFilter) {
  return useInfiniteQuery({ queryKey: keys.list('audit', '', filters), initialPageParam: undefined as string | undefined,
    queryFn: async ({ pageParam, signal }) => unwrap(await api.GET('/v1/audit-log', { signal,
      params: { query: { ...filters, limit: 25, cursor: pageParam } } })),
    getNextPageParam: last => last.page.nextCursor ?? undefined,
  });
}
