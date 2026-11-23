import { Component, ElementRef, inject, viewChild } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { APP_TITLE } from './app-title';
import { TaskStore } from './task-store';

@Component({
  selector: 'app-root',
  imports: [RouterLink, RouterLinkActive, RouterOutlet],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected readonly appTitle = inject(APP_TITLE);
  protected readonly store = inject(TaskStore);
  private readonly main = viewChild.required<ElementRef<HTMLElement>>('main');
  private firstPage = true;

  protected pageChanged(): void {
    if (this.firstPage) {
      this.firstPage = false;
      return;
    }
    this.main().nativeElement.focus();
  }
}
