import { HttpInterceptorFn } from '@angular/common/http';
import { isApiUrl } from './api-url';

// TODO 1: for API addresses only, return next() with a CLONE of the request that has the header
// Accept: application/json, application/problem+json (use request.clone({ setHeaders: { ... } })).
// Other addresses go through unchanged. Requests are immutable: never try to change `request` itself.
export const acceptInterceptor: HttpInterceptorFn = (request, next) => {
  return next(request);
};

// TODO 2: register acceptInterceptor in app.config.ts, as the first item of withInterceptors([...]).
void isApiUrl;
