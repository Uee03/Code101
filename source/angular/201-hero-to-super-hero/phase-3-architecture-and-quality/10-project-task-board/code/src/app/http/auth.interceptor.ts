import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, from, switchMap, throwError } from 'rxjs';
import { AuthService } from '../auth/auth.service';
import { isApiUrl } from './api-url';

// Adds "Authorization: Bearer <token>" to API calls only. On a 401 it renews the token once and sends the request again.
export const authInterceptor: HttpInterceptorFn = (request, next) => {
  if (!isApiUrl(request.url)) {
    return next(request);
  }
  const auth = inject(AuthService);
  const originalToken = auth.token();
  const attach = () => (auth.token() ? request.clone({ setHeaders: { Authorization: `Bearer ${auth.token()}` } }) : request);

  return next(attach()).pipe(
    catchError((error: unknown) => {
      if (!(error instanceof HttpErrorResponse) || error.status !== 401) {
        return throwError(() => error);
      }
      // If another request already renewed the token, do not renew again.
      const renewal =
        auth.token() !== originalToken
          ? Promise.resolve()
          : auth.renew().catch((renewError: unknown) => {
              auth.expired();
              throw renewError;
            });
      return from(renewal).pipe(
        switchMap(() => next(attach())),
        catchError((retryError: unknown) => {
          if (retryError instanceof HttpErrorResponse && retryError.status === 401) {
            auth.expired();
          }
          return throwError(() => retryError);
        })
      );
    })
  );
};
