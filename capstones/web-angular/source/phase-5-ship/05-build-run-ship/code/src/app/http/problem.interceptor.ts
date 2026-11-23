import { inject } from '@angular/core';
import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { catchError, throwError } from 'rxjs';
import { isApiUrl } from '../auth/auth.config';
import { Connectivity } from '../core/connectivity';
import { parseProblem } from './problem';
export const problemInterceptor: HttpInterceptorFn = (request, next) => {
  if (!isApiUrl(request.url)) return next(request);
  const connection = inject(Connectivity);
  return next(request).pipe(catchError(error => {
    if (!(error instanceof HttpErrorResponse) || error.status === 304) return throwError(() => error);
    if (error.status === 0) connection.failed();
    const problemBody = error.headers.get('Content-Type')?.includes('application/problem+json') ? error.error : null;
    return throwError(() => parseProblem(error.status, problemBody, error.headers));
  }));
};
