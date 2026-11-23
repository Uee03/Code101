import { Injectable, signal } from '@angular/core';

// Puts a sentence into a live region (see app.html) so screen readers announce it without moving focus.
@Injectable({ providedIn: 'root' })
export class Announcer {
  private readonly text = signal('');
  readonly message = this.text.asReadonly();

  // The text is cleared first: a live region only announces a change, so the same sentence twice needs a gap.
  say(message: string): void {
    this.text.set('');
    setTimeout(() => this.text.set(message), 50);
  }
}
