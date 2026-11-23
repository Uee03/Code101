import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { AuthService } from '../../auth/auth.service';
@Component({ selector: 'app-dashboard', changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<h1 tabindex="-1">Dashboard</h1><p>Hello, {{ auth.user()?.displayName }}</p>
    <p>Chapter 03 adds teams and API health.</p>` })
export class Dashboard { protected readonly auth = inject(AuthService); }
