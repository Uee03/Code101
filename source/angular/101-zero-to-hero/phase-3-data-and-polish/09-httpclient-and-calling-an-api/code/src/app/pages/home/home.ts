import { Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TaskStore } from '../../task-store';

@Component({
  selector: 'app-home',
  imports: [RouterLink],
  template: `
    <h1>Welcome</h1>
    @if (store.status() === 'ready') {
      <p>Open tasks: {{ store.remaining() }}. Go to the <a routerLink="/tasks">task list</a>.</p>
    } @else {
      <p>Loading your tasks...</p>
    }
  `
})
export class Home {
  protected readonly store = inject(TaskStore);
}
