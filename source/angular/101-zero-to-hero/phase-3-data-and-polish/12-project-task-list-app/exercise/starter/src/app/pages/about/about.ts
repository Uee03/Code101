import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';
// TODO 2: import TaskStats from '../../task-stats' and inject it as a protected readonly `stats`.

@Component({
  selector: 'app-about',
  imports: [RouterLink],
  template: `
    <h1>About</h1>
    <p>Task List is the project of the Code101 Angular 101 track. Your tasks are saved in this browser.</p>
    <!-- TODO 3: show "You have N tasks, M of them high priority." with the two computed signals. -->
    <p><a routerLink="/">Back to the tasks</a></p>
  `
})
export class About {}
