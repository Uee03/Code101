import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { createTask, listTasks, moveTask, removeTask } from '../fake-api';
import type { Status, Task } from '../tasks';

export const taskKeys = {
  all: ['tasks'] as const,
  list: () => [...taskKeys.all, 'list'] as const,
};

export function useTasks() {
  return useQuery({ queryKey: taskKeys.list(), queryFn: listTasks });
}

export function useCreateTask() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (title: string) => createTask(title),
    onSuccess: () => client.invalidateQueries({ queryKey: taskKeys.all }),
  });
}

export function useMoveTask() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: ({ id, status }: { id: number; status: Status }) => moveTask(id, status),
    onMutate: async ({ id, status }) => {
      await client.cancelQueries({ queryKey: taskKeys.list() });
      const previous = client.getQueryData<Task[]>(taskKeys.list());
      client.setQueryData<Task[]>(taskKeys.list(), (old) =>
        old?.map((task) => (task.id === id ? { ...task, status } : task)),
      );
      return { previous };
    },
    onError: (_error, _variables, context) => {
      if (context?.previous) {
        client.setQueryData(taskKeys.list(), context.previous);
      }
    },
    onSettled: () => client.invalidateQueries({ queryKey: taskKeys.list() }),
  });
}

export function useRemoveTask() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => removeTask(id),
    onSuccess: () => client.invalidateQueries({ queryKey: taskKeys.all }),
  });
}
