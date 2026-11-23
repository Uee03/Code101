import { Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TaskStats } from '../../task-stats';

@Component({
  selector: 'app-about',
  imports: [RouterLink],
  template: `
    <h1>About</h1>
    <p>Task List is the project of the Code101 Angular 101 track. Your tasks are saved in this browser.</p>
    <p>You have {{ stats.total() }} tasks, {{ stats.highCount() }} of them high priority.</p>
    <p><a routerLink="/">Back to the tasks</a></p>
  `
})
export class About {
  protected readonly stats = inject(TaskStats);
}
