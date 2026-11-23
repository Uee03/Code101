import { ChangeDetectionStrategy, Component, inject, OnInit } from '@angular/core';
import { AuthService } from '../../auth/auth.service';
@Component({ selector: 'app-callback', changeDetection: ChangeDetectionStrategy.OnPush,
  template: '<h1 tabindex="-1">Callback</h1><p role="status">Signing you in</p>' })
export class Callback implements OnInit {
  private readonly auth = inject(AuthService);
  ngOnInit(): void { void this.auth.finish(); }
}
