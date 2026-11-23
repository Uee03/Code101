import { inject, Injectable, signal } from '@angular/core';
import { Api } from '../../api/api';
import { getHealth } from '../../api/functions';
import { AuthService } from '../../auth/auth.service';
@Injectable({ providedIn: 'root' })
export class DashboardStore {
  private readonly api = inject(Api);
  private readonly auth = inject(AuthService);
  readonly health = signal('checking');
  async load(): Promise<void> { await this.auth.loadMe(); this.health.set((await this.api.invoke(getHealth)).status); }
}
