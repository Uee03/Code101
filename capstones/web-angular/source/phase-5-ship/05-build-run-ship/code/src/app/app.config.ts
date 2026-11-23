import { ApplicationConfig, inject, provideAppInitializer } from '@angular/core';
import { provideHttpClient, withFetch, withInterceptors } from '@angular/common/http';
import { provideRouter, TitleStrategy } from '@angular/router';
import { OAuthStorage, provideOAuthClient } from 'angular-oauth2-oidc';
import { ApiConfiguration } from './api/api-configuration';
import { environment } from '../environments/environment';
import { AuthService } from './auth/auth.service';
import { SplitStorage } from './auth/split-storage';
import { authInterceptor } from './http/auth.interceptor';
import { TitleFocus } from './core/title-focus';
import { problemInterceptor } from './http/problem.interceptor';
import { retryAfterInterceptor } from './http/retry-after.interceptor';
import { routes } from './app.routes';
export const appConfig: ApplicationConfig = {
  providers: [provideHttpClient(withFetch(), withInterceptors([problemInterceptor, authInterceptor, retryAfterInterceptor])), provideRouter(routes), { provide: TitleStrategy, useClass: TitleFocus },
    provideOAuthClient(), { provide: OAuthStorage, useExisting: SplitStorage },
    { provide: ApiConfiguration, useValue: { rootUrl: environment.apiBaseUrl } },
    provideAppInitializer(() => inject(AuthService).boot())],
};
