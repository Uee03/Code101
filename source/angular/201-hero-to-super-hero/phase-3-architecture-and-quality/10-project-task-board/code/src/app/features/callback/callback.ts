import { ChangeDetectionStrategy, Component, inject, OnInit } from '@angular/core';
import { AuthService } from '../../auth/auth.service';

@Component({
  selector: 'app-callback',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <h1>Signing in</h1>
    <p role="status">One moment, finishing the sign-in.</p>
  `
})
export class Callback implements OnInit {
  private readonly auth = inject(AuthService);

  ngOnInit(): void {
    void this.auth.finish();
  }
}
