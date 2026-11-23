import { ChangeDetectionStrategy, Component } from '@angular/core';
import { Search } from './search/search';

@Component({
  selector: 'app-root',
  imports: [Search],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {}
