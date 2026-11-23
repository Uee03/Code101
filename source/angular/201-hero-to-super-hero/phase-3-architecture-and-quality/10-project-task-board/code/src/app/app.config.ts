import { ApplicationConfig, inject, provideAppInitializer, provideBrowserGlobalErrorListeners } from '@angular/core';
import { HttpInterceptorFn, provideHttpClient, withFetch, withInterceptors } from '@angular/common/http';
import { PreloadAllModules, provideRouter, TitleStrategy, withComponentInputBinding, withPreloading } from '@angular/router';
import { OAuthStorage, provideOAuthClient } from 'angular-oauth2-oidc';

import { ApiConfiguration } from './api/api-configuration';
import { environment } from '../environments/environment';
import { routes } from './app.routes';
import { AuthService } from './auth/auth.service';
import { SplitStorage } from './auth/split-storage';
import { TitleFocus } from './core/title-focus';
import { authInterceptor } from './http/auth.interceptor';
import { problemInterceptor } from './http/problem.interceptor';
import { retryAfterInterceptor } from './http/retry-after.interceptor';
import { timingInterceptor } from './http/timing.interceptor';

// Order matters: auth sits inside problem (it must see the raw 401) and outside retryAfter.
const interceptors: HttpInterceptorFn[] = environment.authEnabled
  ? [timingInterceptor, problemInterceptor, authInterceptor, retryAfterInterceptor]
  : [timingInterceptor, problemInterceptor, retryAfterInterceptor];

// The OIDC providers exist only when sign-in is on. Nothing in the app injects AuthService otherwise.
const signIn = environment.authEnabled
  ? [provideOAuthClient(), { provide: OAuthStorage, useExisting: SplitStorage }, provideAppInitializer(() => inject(AuthService).boot())]
  : [];

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideHttpClient(withFetch(), withInterceptors(interceptors)),
    provideRouter(routes, withComponentInputBinding(), withPreloading(PreloadAllModules)),
    { provide: TitleStrategy, useClass: TitleFocus },
    { provide: ApiConfiguration, useValue: { rootUrl: environment.apiBaseUrl } },
    ...signIn
  ]
};
