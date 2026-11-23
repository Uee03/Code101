import { ChangeDetectionStrategy, Component, inject, input, linkedSignal, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TaskPage } from '../../api/models';
import { TaskService } from '../../core/task-service';
import { ApiProblem, isApiProblem } from '../../http/problem';
import { ProblemView } from '../../shared/problem-view';
import { StatusSummary } from '../summary/status-summary';

@Component({
  selector: 'app-tasks',
  imports: [RouterLink, ProblemView, StatusSummary],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './tasks.html',
  styleUrl: './tasks.css'
})
export class Tasks {
  private readonly tasks = inject(TaskService);

  // Filled by the router: the resolver key "page" is bound to this input (withComponentInputBinding).
  readonly page = input.required<TaskPage>();

  // Start from the resolved page, then grow when "Load more" appends. A new resolved page resets both.
  protected readonly items = linkedSignal(() => this.page().items);
  protected readonly nextCursor = linkedSignal(() => this.page().page.nextCursor);
  protected readonly loading = signal(false);
  protected readonly problem = signal<ApiProblem | null>(null);

  protected async loadMore(): Promise<void> {
    const cursor = this.nextCursor();
    if (!cursor || this.loading()) {
      return;
    }
    this.loading.set(true);
    this.problem.set(null);
    try {
      const next = await this.tasks.list({ limit: 5, cursor });
      this.items.update((list) => [...list, ...next.items]);
      this.nextCursor.set(next.page.nextCursor);
    } catch (error) {
      if (!isApiProblem(error)) {
        throw error;
      }
      this.problem.set(error);
    } finally {
      this.loading.set(false);
    }
  }
}
