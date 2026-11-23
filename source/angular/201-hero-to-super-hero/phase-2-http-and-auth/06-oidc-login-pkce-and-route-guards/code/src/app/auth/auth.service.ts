import { computed, inject, Injectable, signal } from '@angular/core';
import { Router } from '@angular/router';
import { OAuthService } from 'angular-oauth2-oidc';
import { Api } from '../api/api';
import { getMe } from '../api/functions';
import { Me } from '../api/models';
import { authConfig, safeReturn } from './auth.config';
import { SplitStorage } from './split-storage';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly oauth = inject(OAuthService);
  private readonly storage = inject(SplitStorage);
  private readonly api = inject(Api);
  private readonly router = inject(Router);
  private renewal: Promise<void> | null = null;

  readonly user = signal<Me | null>(null);
  readonly error = signal('');
  readonly roles = computed(() => this.user()?.roles ?? []);
  readonly isAdmin = computed(() => this.roles().includes('admin'));

  token(): string {
    return this.oauth.getAccessToken();
  }

  signedIn(): boolean {
    return this.oauth.hasValidAccessToken();
  }

  // Runs once before the first screen (see provideAppInitializer in app.config.ts).
  async boot(): Promise<void> {
    this.oauth.configure(authConfig(location.origin));
    this.oauth.events.subscribe((event) => {
      if (event.type === 'token_expires' && 'info' in event && event.info === 'access_token') {
        void this.renew().catch(() => this.expired());
      }
    });
    try {
      await this.oauth.loadDiscoveryDocument();
      if (location.pathname === '/auth/callback') {
        const callbackError = new URLSearchParams(location.search).get('error');
        if (callbackError) {
          throw new Error(callbackError === 'login_required' ? 'Your session ended. Please sign in again.' : callbackError);
        }
        await this.oauth.tryLoginCodeFlow();
        if (!this.signedIn()) {
          throw new Error('Sign-in did not return an access token.');
        }
        await this.loadMe();
        localStorage.setItem('ts.hint', '1');
      } else if (localStorage.getItem('ts.hint') === '1' && !this.signedIn()) {
        this.signIn(location.pathname + location.search, true);
      }
    } catch (error) {
      this.error.set(error instanceof Error ? error.message : 'Sign-in failed. Try again.');
      localStorage.removeItem('ts.hint');
    } finally {
      if (location.pathname === '/auth/callback') {
        history.replaceState(null, '', '/auth/callback');
      }
    }
  }

  async loadMe(): Promise<void> {
    this.user.set(await this.api.invoke(getMe));
  }

  signIn(returnUrl = '/', silent = false): void {
    sessionStorage.setItem('ts.return', safeReturn(returnUrl));
    this.oauth.initCodeFlow('', silent ? { prompt: 'none' } : {});
  }

  // Called by the callback page: go back to where the user wanted to be.
  async finish(): Promise<void> {
    const target = safeReturn(sessionStorage.getItem('ts.return'));
    sessionStorage.removeItem('ts.return');
    await this.router.navigateByUrl(this.signedIn() ? target : '/login', { replaceUrl: true });
  }

  // One renewal at a time: every caller that arrives meanwhile shares the same Promise.
  renew(): Promise<void> {
    if (!this.renewal) {
      this.renewal = this.oauth
        .refreshToken()
        .then(() => undefined)
        .finally(() => {
          this.renewal = null;
        });
    }
    return this.renewal;
  }

  expired(): void {
    this.oauth.logOut(true);
    this.storage.clear();
    this.user.set(null);
    localStorage.removeItem('ts.hint');
    void this.router.navigate(['/login'], { queryParams: { returnUrl: safeReturn(this.router.url) } });
  }

  signOut(): void {
    localStorage.removeItem('ts.hint');
    this.user.set(null);
    // The library reads id_token_hint before it clears its token entries, so call logOut first.
    this.oauth.logOut();
    this.storage.clear();
  }
}
