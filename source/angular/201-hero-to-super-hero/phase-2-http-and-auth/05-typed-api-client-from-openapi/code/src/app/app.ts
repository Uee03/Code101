import { ChangeDetectionStrategy, Component } from '@angular/core';
import { Explorer } from './features/explorer/explorer';

@Component({
  selector: 'app-root',
  imports: [Explorer],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {}
