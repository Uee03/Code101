import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useToast } from '../core/toast';
export function useAction<T>(action: (variables: T) => Promise<unknown>) {
  const cache = useQueryClient(); const toast = useToast();
  return useMutation({ mutationFn: action, retry: false,
    onSuccess: async () => { toast('Saved.'); await cache.invalidateQueries(); },
  });
}
