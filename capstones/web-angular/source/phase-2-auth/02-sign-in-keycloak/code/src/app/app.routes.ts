import { Routes } from '@angular/router';
import { authGuard, adminGuard } from './auth/guards';
export const routes: Routes = [
  { path: 'login', title: 'Login', loadComponent: () => import('./features/login/login').then(m => m.Login) },
  { path: 'auth/callback', title: 'Callback', loadComponent: () => import('./features/callback/callback').then(m => m.Callback) },
  { path: '', title: 'Dashboard', canActivate: [authGuard], loadComponent: () => import('./features/dashboard/dashboard').then(m => m.Dashboard) },
  { path: 'admin/audit', title: 'Audit log', canActivate: [authGuard, adminGuard], loadComponent: () => import('./features/dashboard/dashboard').then(m => m.Dashboard) },
  { path: 'forbidden', title: 'You do not have access', loadComponent: () => import('./features/forbidden/forbidden').then(m => m.Forbidden) },
  { path: '**', title: 'Not found', loadComponent: () => import('./features/not-found/not-found').then(m => m.NotFound) },
];
