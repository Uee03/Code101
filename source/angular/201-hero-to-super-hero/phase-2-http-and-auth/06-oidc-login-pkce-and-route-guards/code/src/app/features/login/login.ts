import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { safeReturn } from '../../auth/auth.config';
import { AuthService } from '../../auth/auth.service';

@Component({
  selector: 'app-login',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <h1>Sign in</h1>
    <p>You sign in on the Keycloak page. This app never sees your password.</p>
    @if (auth.error(); as message) {
      <p role="alert">{{ message }}</p>
    }
    <button type="button" (click)="signIn()">Sign in with Keycloak</button>
  `
})
export class Login {
  protected readonly auth = inject(AuthService);
  private readonly route = inject(ActivatedRoute);

  protected signIn(): void {
    this.auth.signIn(safeReturn(this.route.snapshot.queryParamMap.get('returnUrl')));
  }
}
