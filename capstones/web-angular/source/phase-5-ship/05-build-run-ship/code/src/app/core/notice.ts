import { afterNextRender, inject, Injectable, Injector, signal } from '@angular/core';
import { ApiProblem, parseProblem } from '../http/problem';
@Injectable({ providedIn: 'root' })
export class Notice {
  private readonly injector = inject(Injector);
  activeForm: object | null = null;
  readonly error = signal<ApiProblem | null>(null);
  readonly toast = signal('');
  readonly countdown = signal(0);
  readonly quota = signal('');
  fail(error: unknown): void {
    const value = error as Partial<ApiProblem>;
    this.error.set(value.type && typeof value.status === 'number' ? value as ApiProblem : parseProblem(0, null, { get: () => null }));
    if (value.code === 'last_lead') this.error.update(p => p && ({ ...p, detail: 'Keep at least one lead on the team. Promote another member first.' }));
    afterNextRender(() => document.getElementById('error-summary')?.focus(), { injector: this.injector });
  }
  success(message: string): void { this.error.set(null); this.toast.set(message); }
}
