import { ChangeDetectionStrategy, Component } from '@angular/core';
import { Chooser } from './chooser/chooser';
import { Derived } from './derived/derived';
import { ThemeSwitcher } from './theme/theme-switcher';

@Component({
  selector: 'app-root',
  imports: [Chooser, Derived, ThemeSwitcher],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {}
