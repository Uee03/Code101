import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink, RouterOutlet } from '@angular/router';
import { AuthService } from './auth/auth.service';
@Component({ selector: 'app-root', imports: [RouterLink, RouterOutlet], changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<header><a routerLink="/">Tasks and Teams</a>
    @if (auth.signedIn()) { <button (click)="auth.signOut()">Sign out</button> }
    </header><main><router-outlet /></main>` })
export class App { protected readonly auth = inject(AuthService); }
