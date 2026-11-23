import { inject } from '@angular/core';
import { RedirectCommand, ResolveFn, Router } from '@angular/router';
import { TaskPage } from '../api/models';
import { TaskService, TaskWithEtag } from '../core/task-service';
import { isApiProblem } from '../http/problem';

// Runs before the Tasks page opens. The router waits for the Promise; the result becomes route data named "page".
export const tasksResolver: ResolveFn<TaskPage> = () => inject(TaskService).list({ limit: 5 });

// A missing task redirects to /not-found instead of opening an empty page. Other failures go to /unavailable.
export const taskResolver: ResolveFn<TaskWithEtag> = async (route) => {
  const tasks = inject(TaskService);
  const router = inject(Router);
  try {
    return await tasks.get(route.paramMap.get('taskId') ?? '');
  } catch (error) {
    if (isApiProblem(error) && error.status === 404) {
      return new RedirectCommand(router.parseUrl('/not-found'));
    }
    return new RedirectCommand(router.parseUrl('/unavailable'));
  }
};
