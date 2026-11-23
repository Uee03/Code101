import { Component, signal } from '@angular/core';
import { Greeting } from './greeting/greeting';

@Component({
  selector: 'app-root',
  imports: [Greeting],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected readonly title = 'Tasks First';
  protected readonly taskTitle = 'Write the Angular lesson';
  protected readonly docsUrl = 'https://angular.dev';
  protected readonly done = signal(false);
  protected readonly clicks = signal(0);
  protected readonly note = signal('');
  // TODO 1: add a signal `priority` that starts as 'normal'.

  protected toggleDone(): void {
    this.done.update((value) => !value);
  }

  protected countClick(): void {
    this.clicks.update((count) => count + 1);
  }

  protected updateNote(value: string): void {
    this.note.set(value);
  }

  // TODO 2: add a method `togglePriority()` that switches between 'normal' and 'high' with update().
}
