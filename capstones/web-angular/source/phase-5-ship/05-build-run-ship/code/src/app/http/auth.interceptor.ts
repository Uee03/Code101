import { inject } from '@angular/core';
import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { catchError, from, switchMap, throwError } from 'rxjs';
import { AuthService } from '../auth/auth.service';
import { isApiUrl } from '../auth/auth.config';
export const authInterceptor: HttpInterceptorFn = (request, next) => {
  if (!isApiUrl(request.url)) return next(request);
  const auth = inject(AuthService);
  const originalToken = auth.token();
  const attach = () => auth.token() ? request.clone({ setHeaders: { Authorization: `Bearer ${auth.token()}` } }) : request;
  return next(attach()).pipe(catchError(error => {
    if (!(error instanceof HttpErrorResponse) || error.status !== 401) return throwError(() => error);
    const renewal = auth.token() !== originalToken ? Promise.resolve() : auth.renew().catch(renewError => {
      auth.expired(); throw renewError;
    });
    return from(renewal).pipe(switchMap(() => next(attach())), catchError(retryError => {
      if (retryError instanceof HttpErrorResponse && retryError.status === 401) auth.expired();
      return throwError(() => retryError);
    }));
  }));
};
