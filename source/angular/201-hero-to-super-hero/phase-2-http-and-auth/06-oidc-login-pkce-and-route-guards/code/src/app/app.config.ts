import { ApplicationConfig, inject, provideAppInitializer, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideHttpClient, withFetch, withInterceptors } from '@angular/common/http';
import { provideRouter } from '@angular/router';
import { OAuthStorage, provideOAuthClient } from 'angular-oauth2-oidc';

import { ApiConfiguration } from './api/api-configuration';
import { environment } from '../environments/environment';
import { routes } from './app.routes';
import { AuthService } from './auth/auth.service';
import { SplitStorage } from './auth/split-storage';
import { authInterceptor } from './http/auth.interceptor';
import { problemInterceptor } from './http/problem.interceptor';
import { retryAfterInterceptor } from './http/retry-after.interceptor';
import { timingInterceptor } from './http/timing.interceptor';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideHttpClient(withFetch(), withInterceptors([timingInterceptor, problemInterceptor, authInterceptor, retryAfterInterceptor])),
    provideRouter(routes),
    provideOAuthClient(),
    { provide: OAuthStorage, useExisting: SplitStorage },
    { provide: ApiConfiguration, useValue: { rootUrl: environment.apiBaseUrl } },
    provideAppInitializer(() => inject(AuthService).boot())
  ]
};
