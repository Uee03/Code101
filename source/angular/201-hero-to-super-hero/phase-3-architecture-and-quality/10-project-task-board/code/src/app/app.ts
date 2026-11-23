import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { environment } from '../environments/environment';
import { AuthService } from './auth/auth.service';
import { Announcer } from './core/announcer';

@Component({
  selector: 'app-root',
  imports: [RouterLink, RouterLinkActive, RouterOutlet],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected readonly announcer = inject(Announcer);
  // Only inject the AuthService when sign-in is on: its providers do not exist otherwise.
  protected readonly auth = environment.authEnabled ? inject(AuthService) : null;

  // The app uses <base href="/">, so a plain "#main" link would navigate to "/#main". Move focus by hand instead.
  protected skipToMain(event: Event): void {
    event.preventDefault();
    document.getElementById('main')?.focus();
  }
}
