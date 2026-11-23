import { Component, computed, signal } from '@angular/core';
import { Filter, Task } from './task';

@Component({
  selector: 'app-root',
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected readonly title = 'Tasks First';
  protected readonly filters: readonly Filter[] = ['all', 'todo', 'done'];
  protected readonly tasks = signal<Task[]>([
    { id: 1, title: 'Install Node', done: true },
    { id: 2, title: 'Create the app', done: true },
    { id: 3, title: 'Learn control flow', done: false }
  ]);
  protected readonly filter = signal<Filter>('all');

  protected readonly remaining = computed(() => this.tasks().filter((task) => !task.done).length);
  protected readonly visibleTasks = computed(() => {
    const current = this.filter();
    return this.tasks().filter((task) => current === 'all' || (current === 'done' ? task.done : !task.done));
  });
  // TODO 1: add a computed signal `doneCount` with the number of tasks where done is true.

  protected toggle(id: number): void {
    this.tasks.update((list) => list.map((task) => (task.id === id ? { ...task, done: !task.done } : task)));
  }

  protected setFilter(value: Filter): void {
    this.filter.set(value);
  }

  // TODO 2: add a method `clearDone()` that keeps only the tasks that are not done (use update and filter).
}
