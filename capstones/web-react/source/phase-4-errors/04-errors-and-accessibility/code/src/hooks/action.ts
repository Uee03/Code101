import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useToast } from '../core/toast';
export function useAction<T>(action: (variables: T) => Promise<unknown>) {
  const cache = useQueryClient(); const toast = useToast();
  return useMutation({ mutationFn: async (variables: T) => {
    try { return await action(variables); }
    catch (error) {
      // A create alone may retry once after a network failure, using the same body and key.
      if (error instanceof TypeError && variables && typeof variables === 'object' && 'key' in variables) return action(variables);
      throw error;
    }
  }, retry: false,
    onSuccess: async () => { toast('Saved.'); await cache.invalidateQueries(); },
  });
}
