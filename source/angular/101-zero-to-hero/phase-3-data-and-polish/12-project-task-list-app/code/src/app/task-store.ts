import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { computed, inject, Injectable, signal } from '@angular/core';
import { Task, TaskDraft } from './task';

export type LoadStatus = 'loading' | 'ready' | 'error';

const STORAGE_KEY = 'task-list.tasks';

@Injectable({ providedIn: 'root' })
export class TaskStore {
  private readonly http = inject(HttpClient);
  private readonly items = signal<Task[]>([]);
  private readonly state = signal<LoadStatus>('loading');
  private readonly problem = signal('');
  private readonly note = signal('');

  readonly tasks = this.items.asReadonly();
  readonly status = this.state.asReadonly();
  readonly message = this.problem.asReadonly();
  readonly announcement = this.note.asReadonly();
  readonly remaining = computed(() => this.items().filter((task) => !task.done).length);

  constructor() {
    this.load();
  }

  load(): void {
    const saved = this.readSaved();
    if (saved) {
      this.items.set(saved);
      this.state.set('ready');
      return;
    }
    this.state.set('loading');
    this.http.get<Task[]>('/api/tasks.json').subscribe({
      next: (tasks) => {
        this.items.set(tasks);
        this.state.set('ready');
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

  add(draft: TaskDraft): void {
    const id = Math.max(0, ...this.items().map((task) => task.id)) + 1;
    this.commit([...this.items(), { ...draft, id, done: false }], `Task added: ${draft.title}`);
  }

  toggle(id: number): void {
    const next = this.items().map((task) => (task.id === id ? { ...task, done: !task.done } : task));
    this.commit(next, next.find((task) => task.id === id)?.done ? 'Task marked as done' : 'Task marked as to do');
  }

  remove(id: number): void {
    this.commit(this.items().filter((task) => task.id !== id), 'Task removed');
  }

  private commit(next: Task[], announcement: string): void {
    this.items.set(next);
    this.note.set(announcement);
    localStorage.setItem(STORAGE_KEY, JSON.stringify(next));
  }

  private readSaved(): Task[] | null {
    try {
      const parsed: unknown = JSON.parse(localStorage.getItem(STORAGE_KEY) ?? 'null');
      return Array.isArray(parsed) ? (parsed as Task[]) : null;
    } catch {
      return null;
    }
  }
}
