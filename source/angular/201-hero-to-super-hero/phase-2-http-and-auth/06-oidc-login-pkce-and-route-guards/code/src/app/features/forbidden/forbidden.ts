import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-forbidden',
  imports: [RouterLink],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <h1>You do not have access</h1>
    <p>This page needs a role that your account does not have.</p>
    <a routerLink="/">Go home</a>
  `
})
export class Forbidden {}
