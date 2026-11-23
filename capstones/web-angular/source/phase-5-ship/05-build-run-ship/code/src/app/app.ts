import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { Router, RouterLink, RouterOutlet } from '@angular/router';
import { AuthService } from './auth/auth.service';
import { Actions } from './core/actions';
import { Notice } from './core/notice';
import { Icon } from './shared/icon';
import { Feedback } from './shared/feedback';
@Component({ selector: 'app-root', imports: [RouterLink, RouterOutlet, Icon, Feedback], changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<a class="skip-link" href="#content">Skip to content</a>
    <header><a routerLink="/">Tasks and Teams</a><nav aria-label="Main">
      @if (auth.signedIn()) {
        <a routerLink="/">Dashboard</a><a routerLink="/teams"><app-icon name="users/users" />Teams</a>
        @if (auth.isAdmin()) { <a routerLink="/admin/audit">Audit log</a> }
      }
    </nav><details><summary>Account</summary>
      @if (auth.signedIn()) { <p>{{ auth.user()?.displayName }}</p><button (click)="auth.signOut()"><app-icon name="arrows/log-out" />Sign out</button> }
      @else { <a routerLink="/login"><app-icon name="arrows/log-in" />Sign in</a> }
    </details></header>
    <main id="content" tabindex="-1"><app-feedback (retry)="retry()" /><router-outlet /></main>` })
export class App {
  protected readonly auth = inject(AuthService);
  private readonly actions = inject(Actions);
  protected retry(): void { void this.actions.retry(); }
}
