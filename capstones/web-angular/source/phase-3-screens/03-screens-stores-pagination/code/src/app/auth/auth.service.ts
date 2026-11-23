import { computed, inject, Injectable, signal } from '@angular/core';
import { Router } from '@angular/router';
import { OAuthService } from 'angular-oauth2-oidc';
import { Api } from '../api/api';
import { Me } from '../api/models/me';
import { getMe } from '../api/fn/platform/get-me';
import { SplitStorage } from './split-storage';
import { authConfig, safeReturn } from './auth.config';
@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly oauth = inject(OAuthService);
  private readonly storage = inject(SplitStorage);
  private readonly api = inject(Api);
  private readonly router = inject(Router);
  readonly user = signal<Me | null>(null);
  readonly error = signal('');
  readonly roles = computed(() => this.user()?.roles ?? []);
  readonly scopes = computed(() => this.user()?.scopes ?? []);
  readonly isAdmin = computed(() => this.roles().includes('admin'));
  private renewal: Promise<void> | null = null;
  private loadingMe = false;
  token(): string { return this.oauth.getAccessToken(); }
  signedIn(): boolean { return this.oauth.hasValidAccessToken(); }
  hasScope(scope: string): boolean { return this.scopes().includes(scope); }
  isLead(teamId: string): boolean {
    return this.isAdmin() || !!this.user()?.teams.some(t => t.teamId === teamId && t.role === 'lead');
  }
  async boot(): Promise<void> {
    this.oauth.configure(authConfig(location.origin, sessionStorage.getItem('ts.adminStep') === '1'));
    this.oauth.events.subscribe(event => {
      if (event.type === 'token_expires' && 'info' in event && event.info === 'access_token') {
        void this.renew().catch(() => this.expired());
      }
    });
    try {
      await this.oauth.loadDiscoveryDocument();
      if (location.pathname === '/auth/callback') {
        const callbackError = new URLSearchParams(location.search).get('error');
        if (callbackError) throw new Error(callbackError);
        await this.oauth.tryLoginCodeFlow();
        if (!this.signedIn()) throw new Error('Sign-in did not return an access token');
        await this.loadMe();
        localStorage.setItem('ts.hint', '1');
      } else if (localStorage.getItem('ts.hint') === '1' && !this.signedIn()) {
        await this.signIn(location.pathname + location.search, false, true);
      }
    } catch (error) {
      this.error.set(error instanceof Error ? error.message : 'Sign-in failed. Try again.');
      localStorage.removeItem('ts.hint');
    } finally {
      if (location.pathname === '/auth/callback') {
        history.replaceState(null, '', '/auth/callback');
        sessionStorage.removeItem('ts.adminStep');
      }
    }
  }
  async loadMe(): Promise<void> {
    this.loadingMe = true;
    try { this.user.set(await this.api.invoke(getMe)); }
    finally { this.loadingMe = false; }
  }
  async signIn(returnUrl = '/', admin = false, silent = false): Promise<void> {
    sessionStorage.setItem('ts.return', safeReturn(returnUrl));
    if (admin) sessionStorage.setItem('ts.adminStep', '1');
    this.oauth.scope = authConfig(location.origin, admin).scope!;
    this.oauth.initCodeFlow('', silent ? { prompt: 'none' } : {});
  }
  async finish(): Promise<void> {
    const target = safeReturn(sessionStorage.getItem('ts.return'));
    sessionStorage.removeItem('ts.return');
    await this.router.navigateByUrl(this.signedIn() ? target : '/login', { replaceUrl: true });
  }
  renew(): Promise<void> {
    if (!this.renewal) {
      this.renewal = this.oauth.refreshToken().then(() => undefined).finally(() => { this.renewal = null; });
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
    // The library reads id_token_hint before clearing its token entries.
    this.oauth.logOut();
    this.storage.clear();
  }
}
