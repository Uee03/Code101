import { computed, inject, Injectable, signal } from '@angular/core';
import { CursorList, Creation, Versioned } from './core/state';
import { ApiError, FakeApi } from './fake-api';
import { etagOf, Task } from './task';

@Injectable({ providedIn: 'root' })
export class TaskStore {
  private readonly api = inject(FakeApi);
  private readonly creation = new Creation();
  private readonly text = signal('');
  private readonly working = signal(false);

  readonly list = new CursorList<Task>();
  readonly detail = signal<Versioned<Task> | null>(null);
  readonly message = this.text.asReadonly();
  readonly saving = this.working.asReadonly();

  readonly tasks = computed(() => this.list.state().items);
  readonly status = computed(() => this.list.state().status);
  readonly canLoadMore = computed(() => this.list.state().nextCursor !== null && this.status() === 'idle');
  readonly openCount = computed(() => this.tasks().filter((task) => !task.done).length);

  load(): Promise<void> {
    this.text.set('');
    return this.list.load((cursor) => this.api.list(cursor));
  }

  more(): Promise<void> {
    return this.list.more();
  }

  async show(id: number): Promise<void> {
    try {
      this.detail.set(await this.api.get(id));
    } catch (error) {
      this.text.set(error instanceof Error ? error.message : 'Could not load the task.');
    }
  }

  // Optimistic update: show the change at once, send it, and undo it if the server refuses.
  async toggle(task: Task): Promise<void> {
    const before = this.list.snapshot();
    this.text.set('');
    this.working.set(true);
    this.list.replace({ ...task, done: !task.done }, (item) => item.id === task.id);
    try {
      const saved = await this.api.patch(task.id, { done: !task.done }, etagOf(task));
      this.list.replace(saved.value, (item) => item.id === task.id);
    } catch (error) {
      this.list.restore(before);
      if (error instanceof ApiError && error.status === 412) {
        const fresh = await this.api.get(task.id);
        this.list.replace(fresh.value, (item) => item.id === task.id);
        this.text.set('Someone else changed this task first. It was reloaded: check it and try again.');
      } else {
        this.text.set('Could not save. Your change was undone.');
      }
    } finally {
      this.working.set(false);
    }
  }

  async add(title: string): Promise<boolean> {
    this.text.set('');
    try {
      const task = await this.creation.send({ title }, (key, body) => this.api.create(key, body));
      this.list.append(task);
      return true;
    } catch (error) {
      this.text.set(`${error instanceof Error ? error.message : 'Could not add the task.'} Press Add again: the retry is safe.`);
      return false;
    }
  }

  changeElsewhere(id: number): void {
    this.api.changeElsewhere(id);
  }
}
