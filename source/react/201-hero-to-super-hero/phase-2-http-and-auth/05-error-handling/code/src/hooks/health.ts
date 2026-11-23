import { useQuery } from '@tanstack/react-query';
import { api } from '../api/client';
import type { Health } from '../api/types';

export function useHealth() {
  return useQuery({
    queryKey: ['health'],
    queryFn: async ({ signal }): Promise<Health> => {
      const { data, error, response } = await api.GET('/health', { signal });
      const body = data ?? error;
      if (!body) {
        throw new Error(`The health check failed (${response.status})`);
      }
      return body;
    },
    retry: false,
  });
}
