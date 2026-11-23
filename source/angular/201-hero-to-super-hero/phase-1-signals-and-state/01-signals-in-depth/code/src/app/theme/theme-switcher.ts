import { ChangeDetectionStrategy, Component, effect, signal, untracked } from '@angular/core';

type Theme = 'light' | 'dark';

const STORAGE_KEY = 'signals-lab.theme';

function readTheme(): Theme {
  return localStorage.getItem(STORAGE_KEY) === 'dark' ? 'dark' : 'light';
}

@Component({
  selector: 'app-theme-switcher',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './theme-switcher.html'
})
export class ThemeSwitcher {
  protected readonly theme = signal<Theme>(readTheme());
  protected readonly changes = signal(0);

  constructor() {
    // A side effect: it syncs the signal to things outside Angular (the page and the browser storage).
    effect(() => {
      const value = this.theme();
      document.documentElement.dataset['theme'] = value;
      localStorage.setItem(STORAGE_KEY, value);
      console.log(`theme is ${value} after ${untracked(this.changes)} changes`);
    });
  }

  protected toggle(): void {
    this.theme.update((value) => (value === 'light' ? 'dark' : 'light'));
    this.changes.update((count) => count + 1);
  }
}
