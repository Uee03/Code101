import { Routes } from '@angular/router';
import { adminGuard, authGuard } from './auth/guards';
import { Admin } from './features/admin/admin';
import { Callback } from './features/callback/callback';
import { Explorer } from './features/explorer/explorer';
import { Forbidden } from './features/forbidden/forbidden';
import { Home } from './features/home/home';
import { Login } from './features/login/login';

export const routes: Routes = [
  { path: 'login', component: Login, title: 'Sign in' },
  { path: 'auth/callback', component: Callback, title: 'Signing in' },
  { path: '', component: Home, canActivate: [authGuard], title: 'Home' },
  { path: 'explorer', component: Explorer, canActivate: [authGuard], title: 'API explorer' },
  { path: 'admin', component: Admin, canActivate: [authGuard, adminGuard], title: 'Admin' },
  { path: 'forbidden', component: Forbidden, title: 'No access' },
  { path: '**', redirectTo: '' }
];
