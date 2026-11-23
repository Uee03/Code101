import { ChangeDetectionStrategy, Component } from '@angular/core';
import { Board } from './board/board';

@Component({
  selector: 'app-root',
  imports: [Board],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {}
