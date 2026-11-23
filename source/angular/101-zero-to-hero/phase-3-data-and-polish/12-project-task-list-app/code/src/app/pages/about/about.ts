import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-about',
  imports: [RouterLink],
  template: `
    <h1>About</h1>
    <p>Task List is the project of the Code101 Angular 101 track. Your tasks are saved in this browser.</p>
    <p><a routerLink="/">Back to the tasks</a></p>
  `
})
export class About {}
