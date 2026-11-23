import { ChangeDetectionStrategy, Component, inject, OnInit } from '@angular/core';
import { RouterLink } from '@angular/router';
import { AuthService } from '../../auth/auth.service';
import { Actions } from '../../core/actions';
import { DashboardStore } from './dashboard.store';
@Component({ selector: 'app-dashboard', imports: [RouterLink], changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<h1 tabindex="-1">Dashboard</h1><p>Hello, {{ auth.user()?.displayName }}</p>
    <p>Roles: {{ auth.roles().join(', ') }}</p><p>Scopes: {{ auth.scopes().join(', ') }}</p>
    <p role="status">API: {{ store.health() }}</p><h2>My teams</h2><ul>
    @for (team of auth.user()?.teams ?? []; track team.teamId) {
      <li><a [routerLink]="['/teams', team.teamId]">{{ team.name }}</a> ({{ team.role }})</li>
    }</ul>` })
export class Dashboard implements OnInit {
  protected readonly auth = inject(AuthService);
  protected readonly store = inject(DashboardStore);
  private readonly actions = inject(Actions);
  ngOnInit(): void { void this.actions.run(() => this.store.load()); }
}
