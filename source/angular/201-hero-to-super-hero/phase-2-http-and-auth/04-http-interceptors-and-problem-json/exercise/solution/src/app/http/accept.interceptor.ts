import { HttpInterceptorFn } from '@angular/common/http';
import { isApiUrl } from './api-url';

export const acceptInterceptor: HttpInterceptorFn = (request, next) => {
  if (!isApiUrl(request.url)) {
    return next(request);
  }
  return next(request.clone({ setHeaders: { Accept: 'application/json, application/problem+json' } }));
};
