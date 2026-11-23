import { ChangeDetectionStrategy, Component } from '@angular/core';
@Component({
  selector: 'app-root',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: '<main><h1>Tasks and Teams</h1><p>Generated client ready. Chapter 02 adds sign-in.</p></main>',
})
export class App {}
