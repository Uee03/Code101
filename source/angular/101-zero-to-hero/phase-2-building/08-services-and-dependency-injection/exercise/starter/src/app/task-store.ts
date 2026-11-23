import { computed, Injectable, signal } from '@angular/core';
import { Task } from './task';
import { INITIAL_TASKS } from './task-data';

@Injectable({ providedIn: 'root' })
export class TaskStore {
  private readonly items = signal<Task[]>([...INITIAL_TASKS]);

  readonly tasks = this.items.asReadonly();
  readonly remaining = computed(() => this.items().filter((task) => !task.done).length);
  // TODO 1: add a computed signal `doneCount` with the number of finished tasks.

  byId(id: number): Task | undefined {
    return this.items().find((task) => task.id === id);
  }

  add(title: string): void {
    const id = Math.max(0, ...this.items().map((task) => task.id)) + 1;
    this.items.update((list) => [...list, { id, title, done: false }]);
  }

  toggle(id: number): void {
    this.items.update((list) => list.map((task) => (task.id === id ? { ...task, done: !task.done } : task)));
  }

  remove(id: number): void {
    this.items.update((list) => list.filter((task) => task.id !== id));
  }

  // TODO 2: add a method `clearDone()` that removes every finished task.
}
