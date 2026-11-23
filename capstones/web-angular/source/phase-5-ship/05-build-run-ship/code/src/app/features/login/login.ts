import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { AuthService } from '../../auth/auth.service';
import { safeReturn } from '../../auth/auth.config';
@Component({ selector: 'app-login', changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<h1 tabindex="-1">Login</h1><p>Use your Tasks and Teams account on the Keycloak page.</p>
    @if (auth.error()) { <p role="alert">{{ auth.error() }}</p> }
    <button type="button" (click)="signIn()">Sign in</button>` })
export class Login {
  protected readonly auth = inject(AuthService);
  private readonly route = inject(ActivatedRoute);
  protected signIn(): void {
    void this.auth.signIn(safeReturn(this.route.snapshot.queryParamMap.get('returnUrl')));
  }
}
