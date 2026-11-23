import { Component, computed, signal } from '@angular/core';
import { NewTaskReactive } from './new-task-reactive/new-task-reactive';
import { NewTaskTemplate } from './new-task-template/new-task-template';
import { TaskItem } from './task-item/task-item';
import { Filter, Task } from './task';

@Component({
  selector: 'app-root',
  imports: [NewTaskReactive, NewTaskTemplate, TaskItem],
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

  protected add(title: string): void {
    const id = Math.max(0, ...this.tasks().map((task) => task.id)) + 1;
    this.tasks.update((list) => [...list, { id, title, done: false }]);
  }

  protected toggle(id: number): void {
    this.tasks.update((list) => list.map((task) => (task.id === id ? { ...task, done: !task.done } : task)));
  }

  protected remove(id: number): void {
    this.tasks.update((list) => list.filter((task) => task.id !== id));
  }

  protected setFilter(value: Filter): void {
    this.filter.set(value);
  }
}
