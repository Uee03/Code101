import { Component } from '@angular/core';
// TODO 1: import RouterLink from '@angular/router' and add it to the `imports` array below.

@Component({
  selector: 'app-about',
  template: `
    <h1>About</h1>
    <p>Tasks First is the practice app of the Code101 Angular 101 track.</p>
    <!-- TODO 2: add a paragraph with a link to "/tasks" whose text is "See the tasks" (routerLink). -->
  `
})
export class About {}
