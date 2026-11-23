import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';
@Component({ selector: 'app-forbidden', imports: [RouterLink], changeDetection: ChangeDetectionStrategy.OnPush,
  template: '<h1 tabindex="-1">You do not have access</h1><p>An administrator is required.</p><a routerLink="/">Go home</a>' })
export class Forbidden {}
