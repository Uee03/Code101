import { afterNextRender, inject, Injectable, Injector } from '@angular/core';
import { Title } from '@angular/platform-browser';
import { RouterStateSnapshot, TitleStrategy } from '@angular/router';

// After each navigation: set the tab title from the route's `title`, then move focus to the page heading.
// Without it, a keyboard or screen-reader user stays on the link they pressed and hears nothing about the new page.
@Injectable({ providedIn: 'root' })
export class TitleFocus extends TitleStrategy {
  private readonly title = inject(Title);
  private readonly injector = inject(Injector);
  private firstNavigation = true;

  override updateTitle(snapshot: RouterStateSnapshot): void {
    this.title.setTitle(`${this.buildTitle(snapshot) ?? 'Page'} | Task board`);
    // Leave focus alone on the first page load: the skip link must stay the first Tab stop.
    if (this.firstNavigation) {
      this.firstNavigation = false;
      return;
    }
    afterNextRender(
      () => {
        const heading = document.querySelector<HTMLElement>('main h1');
        heading?.setAttribute('tabindex', '-1');
        heading?.focus();
      },
      { injector: this.injector }
    );
  }
}
