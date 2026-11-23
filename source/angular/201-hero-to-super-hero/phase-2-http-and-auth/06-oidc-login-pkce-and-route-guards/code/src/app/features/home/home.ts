import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { AuthService } from '../../auth/auth.service';

@Component({
  selector: 'app-home',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <h1>Home</h1>
    @if (auth.user(); as user) {
      <p>Hello, {{ user.displayName }}.</p>
      <p>Roles: {{ user.roles.join(', ') }}. Scopes: {{ user.scopes.join(', ') }}.</p>
      <h2>Your teams</h2>
      <ul>
        @for (team of user.teams; track team.teamId) {
          <li>{{ team.name }} ({{ team.role }})</li>
        }
      </ul>
    }
  `
})
export class Home {
  protected readonly auth = inject(AuthService);
}
