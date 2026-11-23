import { inject, Injectable, signal, DestroyRef } from '@angular/core';
import { fromEvent, merge } from 'rxjs';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
@Injectable({ providedIn: 'root' })
export class Connectivity {
  readonly online = signal(navigator.onLine);
  constructor() {
    merge(fromEvent(window, 'online'), fromEvent(window, 'offline')).pipe(takeUntilDestroyed(inject(DestroyRef)))
      .subscribe(() => this.online.set(navigator.onLine));
  }
  failed(): void { this.online.set(false); }
  retry(): void { this.online.set(navigator.onLine); }
}
