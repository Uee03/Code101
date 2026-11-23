import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-home',
  imports: [RouterLink],
  template: `
    <h1>Welcome</h1>
    <p>This is the home page. Go to the <a routerLink="/tasks">task list</a>.</p>
  `
})
export class Home {}
