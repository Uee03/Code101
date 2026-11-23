import { ChangeDetectionStrategy, Component, inject, output } from '@angular/core';
import { Notice } from '../core/notice';
import { Connectivity } from '../core/connectivity';
import { Icon } from './icon';
@Component({ selector: 'app-feedback', imports: [Icon], changeDetection: ChangeDetectionStrategy.OnPush,
  template: `@if (!connection.online()) { <aside role="status"><app-icon name="cloud-network/cloud-off" /> Offline. Writes are disabled.</aside> }
    @if (notice.quota()) { <p role="status">{{ notice.quota() }}</p> }
    @if (notice.countdown()) { <p role="status">Too many requests, retrying in {{ notice.countdown() }} s</p> }
    @if (notice.error(); as error) {
      <section id="error-summary" tabindex="-1" role="alert">
        <h2>{{ error.status === 403 ? 'You do not have access' : error.status === 404 ? 'Not found' : 'Request failed' }}</h2>
        <p>{{ error.detail }}</p>@if (error.status === 429) { <p>Wait {{ error.retryAfter ?? 1 }} seconds before submitting again. Writes are never retried automatically.</p> }
        @if (error.traceId) { <p>Support trace: {{ error.traceId }}</p> }
        @for (field of error.errors ?? []; track field.pointer) { <p>{{ field.pointer }}: {{ field.detail }}</p> }
        @if (error.status !== 403 && error.status !== 404) { <button (click)="retry.emit()"><app-icon name="arrows/refresh-cw" />Try again</button> }
        <button aria-label="Dismiss error" (click)="notice.error.set(null)"><app-icon name="ui/x" /></button>
      </section>
    }
    <p role="status" aria-live="polite"><app-icon name="ui/check-circle" />{{ notice.toast() }}</p>` })
export class Feedback {
  protected readonly notice = inject(Notice);
  protected readonly connection = inject(Connectivity);
  readonly retry = output<void>();
}
