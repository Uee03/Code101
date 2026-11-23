import { inject } from '@angular/core';
import { HttpErrorResponse, HttpInterceptorFn, HttpResponse } from '@angular/common/http';
import { catchError, finalize, switchMap, tap, throwError, timer } from 'rxjs';
import { isApiUrl } from '../auth/auth.config';
import { Notice } from '../core/notice';
import { parseProblem } from './problem';
export const retryAfterInterceptor: HttpInterceptorFn = (request, next) => {
  if (!isApiUrl(request.url)) return next(request);
  const notice = inject(Notice);
  return next(request).pipe(tap(response => {
    if (response instanceof HttpResponse && new URL(request.url).pathname !== '/health' && response.headers.get('RateLimit-Remaining') === '0') {
      notice.quota.set('Request budget exhausted. Wait before your next action.');
    }
  }), catchError(error => {
    if (!(error instanceof HttpErrorResponse) || error.status !== 429) return throwError(() => error);
    const seconds = parseProblem(429, error.error, error.headers).retryAfter ?? 1;
    if (request.method !== 'GET') return throwError(() => error);
    notice.countdown.set(seconds);
    const clock = setInterval(() => notice.countdown.update(n => Math.max(0, n - 1)), 1000);
    return timer(seconds * 1000).pipe(switchMap(() => next(request)), finalize(() => {
      clearInterval(clock); notice.countdown.set(0);
    }));
  }));
};
