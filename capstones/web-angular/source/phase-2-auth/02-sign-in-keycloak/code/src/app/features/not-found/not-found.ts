import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';
@Component({ selector: 'app-not-found', imports: [RouterLink], changeDetection: ChangeDetectionStrategy.OnPush,
  template: '<h1 tabindex="-1">Not found</h1><p>This page is not available.</p><a routerLink="/">Go home</a>' })
export class NotFound {}
