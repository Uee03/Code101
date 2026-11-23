import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { Role } from '../api/models';
import { AuthService } from './auth.service';

// A guard factory: roleGuard('admin') returns a guard that only lets users with that role in.
export function roleGuard(role: Role): CanActivateFn {
  return () => inject(AuthService).roles().includes(role) || inject(Router).createUrlTree(['/forbidden']);
}
