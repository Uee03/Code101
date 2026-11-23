import { Injectable, signal } from '@angular/core';
@Injectable({ providedIn: 'root' })
export class Notice {
  readonly error = signal<{ status: number; detail: string; traceId?: string; errors?: { pointer: string; detail: string }[] } | null>(null);
  readonly toast = signal('');
  readonly countdown = signal(0);
  fail(error: unknown): void {
    const response = error as { status?: number; error?: { detail?: string; traceId?: string } };
    this.error.set({ status: response.status ?? 0, detail: response.error?.detail ?? 'Request failed. Try again.', traceId: response.error?.traceId });
  }
  success(message: string): void { this.error.set(null); this.toast.set(message); }
}
