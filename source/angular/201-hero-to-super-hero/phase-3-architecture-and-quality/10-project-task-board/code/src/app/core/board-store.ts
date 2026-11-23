import { computed, inject, Injectable, signal } from '@angular/core';
import { Task, TaskStatus } from '../api/models';
import { ApiProblem, isApiProblem } from '../http/problem';
import { Announcer } from './announcer';
import { TaskService } from './task-service';

export interface Column {
  status: TaskStatus;
  title: string;
}

// The four columns of the board. "cancelled" tasks are not shown. The titles are translated at build time.
export const COLUMNS: readonly Column[] = [
  { status: 'todo', title: $localize`:@@col.todo:To do` },
  { status: 'in_progress', title: $localize`:@@col.in_progress:In progress` },
  { status: 'blocked', title: $localize`:@@col.blocked:Blocked` },
  { status: 'done', title: $localize`:@@col.done:Done` }
];

// Server state of the board: the tasks, the loading flag and the last problem. Pages read signals and call methods.
@Injectable({ providedIn: 'root' })
export class BoardStore {
  private readonly tasks = inject(TaskService);
  private readonly announcer = inject(Announcer);
  private readonly items = signal<readonly Task[]>([]);

  readonly loading = signal(false);
  readonly problem = signal<ApiProblem | null>(null);
  readonly columns = computed(() => COLUMNS.map((column) => ({ ...column, tasks: this.items().filter((task) => task.status === column.status) })));

  async load(): Promise<void> {
    this.loading.set(true);
    this.problem.set(null);
    try {
      const all: Task[] = [];
      let cursor: string | undefined;
      // The cap protects against a server that never ends the list.
      for (let pages = 0; pages < 10; pages++) {
        const page = await this.tasks.list({ limit: 100, cursor });
        all.push(...page.items);
        if (!page.page.nextCursor) {
          break;
        }
        cursor = page.page.nextCursor;
      }
      this.items.set(all);
    } catch (error) {
      if (!isApiProblem(error)) {
        throw error;
      }
      this.problem.set(error);
    } finally {
      this.loading.set(false);
    }
  }

  // Optimistic move: show the change at once, send it with If-Match, and put the old task back if it fails.
  async move(taskId: string, status: TaskStatus): Promise<void> {
    const before = this.items().find((task) => task.id === taskId);
    if (!before || before.status === status) {
      return;
    }
    this.replace({ ...before, status });
    this.problem.set(null);
    try {
      // The contract defines the ETag as the quoted version, so a list item carries everything we need.
      const result = await this.tasks.update(taskId, `"${before.version}"`, { status });
      this.replace(result.task);
      this.announcer.say($localize`:@@board.moved:The task was moved.`);
    } catch (error) {
      this.replace(before);
      if (!isApiProblem(error)) {
        throw error;
      }
      this.problem.set(error);
      this.announcer.say($localize`:@@board.failed:The task could not be moved.`);
      if (error.status === 412) {
        // Someone else changed it first: read the board again so the user sees the current state, and keep the message.
        await this.load();
        this.problem.set(error);
      }
    }
  }

  private replace(task: Task): void {
    this.items.update((list) => list.map((item) => (item.id === task.id ? task : item)));
  }
}
