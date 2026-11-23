import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from './auth.service';
import { safeReturn } from './auth.config';
export const authGuard: CanActivateFn = (_route, state) => {
  const auth = inject(AuthService);
  return auth.signedIn() || inject(Router).createUrlTree(['/login'], { queryParams: { returnUrl: safeReturn(state.url) } });
};
export const adminGuard: CanActivateFn = async (_route, state) => {
  const auth = inject(AuthService);
  if (!auth.isAdmin()) return inject(Router).createUrlTree(['/forbidden']);
  if (!auth.hasScope('tasks:admin')) { await auth.signIn(state.url, true, true); return false; }
  return true;
};
