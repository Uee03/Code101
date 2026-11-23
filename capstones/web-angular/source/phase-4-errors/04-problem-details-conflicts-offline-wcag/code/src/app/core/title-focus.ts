import { afterNextRender, inject, Injectable, Injector } from '@angular/core';
import { TitleStrategy, RouterStateSnapshot } from '@angular/router';
import { Title } from '@angular/platform-browser';
@Injectable({ providedIn: 'root' })
export class TitleFocus extends TitleStrategy {
  private readonly title = inject(Title);
  private readonly injector = inject(Injector);
  override updateTitle(snapshot: RouterStateSnapshot): void {
    this.title.setTitle(`${this.buildTitle(snapshot) ?? 'Tasks and Teams'} | Tasks and Teams`);
    afterNextRender(() => document.querySelector<HTMLElement>('main h1')?.focus(), { injector: this.injector });
  }
}
