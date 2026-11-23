import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { safeReturn } from './auth.config';
import { AuthService } from './auth.service';

// Not signed in: go to /login and remember where the user wanted to go.
export const authGuard: CanActivateFn = (_route, state) => {
  const auth = inject(AuthService);
  return auth.signedIn() || inject(Router).createUrlTree(['/login'], { queryParams: { returnUrl: safeReturn(state.url) } });
};

// Signed in but not an administrator: show the "no access" page. Roles come from getMe, not from the token.
export const adminGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  return auth.isAdmin() || inject(Router).createUrlTree(['/forbidden']);
};
