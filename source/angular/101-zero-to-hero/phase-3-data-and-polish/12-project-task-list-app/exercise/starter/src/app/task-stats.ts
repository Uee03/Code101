import { computed, inject, Injectable } from '@angular/core';
import { TaskStore } from './task-store';

@Injectable({ providedIn: 'root' })
export class TaskStats {
  private readonly store = inject(TaskStore);

  readonly total = computed(() => this.store.tasks().length);
  // TODO 1: add a computed signal `highCount` with the number of tasks whose priority is 'high'.
}
