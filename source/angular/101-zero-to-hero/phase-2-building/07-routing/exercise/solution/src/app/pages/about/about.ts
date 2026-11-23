import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-about',
  imports: [RouterLink],
  template: `
    <h1>About</h1>
    <p>Tasks First is the practice app of the Code101 Angular 101 track.</p>
    <p><a routerLink="/tasks">See the tasks</a></p>
  `
})
export class About {}
