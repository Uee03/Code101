import { Injectable, signal } from '@angular/core';
@Injectable({ providedIn: 'root' })
export class Connectivity {
  readonly online = signal(navigator.onLine);
}
