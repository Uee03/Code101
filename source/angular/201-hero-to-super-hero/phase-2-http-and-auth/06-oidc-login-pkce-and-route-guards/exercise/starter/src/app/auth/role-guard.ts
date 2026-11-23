import { CanActivateFn } from '@angular/router';
import { Role } from '../api/models';

// A guard factory: roleGuard('admin') returns a guard that only lets users with that role in.
export function roleGuard(role: Role): CanActivateFn {
  // TODO 1: inside the returned function use inject(AuthService).roles() and inject(Router).
  // TODO 2: return true when roles() includes `role`, otherwise a UrlTree for '/forbidden'.
  void role;
  return () => {
    throw new Error('TODO: write roleGuard');
  };
}
