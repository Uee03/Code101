import '@angular/compiler';
import { createEnvironmentInjector, EnvironmentInjector, Injector, provideZonelessChangeDetection, ɵINJECTOR_SCOPE } from '@angular/core';
import { HttpClient, provideHttpClient, withFetch, withInterceptors } from '@angular/common/http';
import { Api } from '../src/app/api/api';
import { environment } from '../src/environments/environment';
export function nodeClient(token = '') {
  const injector = createEnvironmentInjector([
    { provide: ɵINJECTOR_SCOPE, useValue: 'root' },
    provideZonelessChangeDetection(),
    provideHttpClient(withFetch(), withInterceptors([(request, next) => {
      const target = new URL(request.url);
      const base = new URL(environment.apiBaseUrl);
      const allowed = target.origin === base.origin &&
        (target.pathname === base.pathname || target.pathname.startsWith(base.pathname.replace(/\/$/, '') + '/'));
      return next(allowed && token ? request.clone({ setHeaders: { Authorization: `Bearer ${token}` } }) : request);
    }])),
  ], Injector.NULL as EnvironmentInjector);
  const api = new Api({ rootUrl: environment.apiBaseUrl }, injector.get(HttpClient));
  return { api, close: () => injector.destroy() };
}
