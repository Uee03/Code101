import { ChangeDetectionStrategy, Component } from '@angular/core';
import { Demo } from './features/demo/demo';

@Component({
  selector: 'app-root',
  imports: [Demo],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {}
