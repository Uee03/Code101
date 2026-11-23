import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
  selector: 'app-admin',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <h1>Admin</h1>
    <p>Only administrators reach this page. The guard decides in the browser; the API still checks the role on every call.</p>
  `
})
export class Admin {}
