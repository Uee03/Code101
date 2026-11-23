import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { computed, inject, Injectable, signal } from '@angular/core';
import { Task } from './task';

export type LoadStatus = 'loading' | 'ready' | 'error';

@Injectable({ providedIn: 'root' })
export class TaskStore {
  private readonly http = inject(HttpClient);
  private readonly items = signal<Task[]>([]);
  private readonly state = signal<LoadStatus>('loading');
  private readonly problem = signal('');
  private readonly loaded = signal<Date | null>(null);

  readonly tasks = this.items.asReadonly();
  readonly status = this.state.asReadonly();
  readonly message = this.problem.asReadonly();
  readonly lastLoaded = this.loaded.asReadonly();
  readonly remaining = computed(() => this.items().filter((task) => !task.done).length);

  constructor() {
    this.load();
  }

  load(url = '/api/tasks.json'): void {
    this.state.set('loading');
    this.http.get<Task[]>(url).subscribe({
      next: (tasks) => {
        this.items.set(tasks);
        this.state.set('ready');
        this.loaded.set(new Date());
      },
      error: (error: HttpErrorResponse) => {
        this.problem.set(error.status === 0 ? 'Cannot reach the server.' : `The server answered with status ${error.status}.`);
        this.state.set('error');
      }
    });
  }

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
}
