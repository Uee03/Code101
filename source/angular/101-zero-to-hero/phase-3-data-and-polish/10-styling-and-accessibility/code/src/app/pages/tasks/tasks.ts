import { Component, computed, inject, signal } from '@angular/core';
import { NewTaskReactive } from '../../new-task-reactive/new-task-reactive';
import { TaskItem } from '../../task-item/task-item';
import { Filter } from '../../task';
import { TaskStore } from '../../task-store';

@Component({
  selector: 'app-tasks-page',
  imports: [NewTaskReactive, TaskItem],
  templateUrl: './tasks.html',
  styleUrl: './tasks.css'
})
export class TasksPage {
  protected readonly store = inject(TaskStore);
  protected readonly filters: readonly Filter[] = ['all', 'todo', 'done'];
  protected readonly filter = signal<Filter>('all');
  protected readonly brokenUrl = 'http://localhost:9/api/tasks.json';

  protected readonly visibleTasks = computed(() => {
    const current = this.filter();
    return this.store.tasks().filter((task) => current === 'all' || (current === 'done' ? task.done : !task.done));
  });

  protected setFilter(value: Filter): void {
    this.filter.set(value);
  }
}
