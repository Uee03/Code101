import { computed, inject, Injectable } from '@angular/core';
import { TaskStore } from './task-store';

@Injectable({ providedIn: 'root' })
export class TaskStats {
  private readonly store = inject(TaskStore);

  readonly total = computed(() => this.store.tasks().length);
  readonly highCount = computed(() => this.store.tasks().filter((task) => task.priority === 'high').length);
}
