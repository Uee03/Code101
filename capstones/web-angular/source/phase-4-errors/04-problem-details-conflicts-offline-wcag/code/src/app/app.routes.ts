import { Routes } from '@angular/router';
import { authGuard, adminGuard } from './auth/guards';
export const routes: Routes = [
  { path: 'login', title: 'Login', loadComponent: () => import('./features/login/login').then(m => m.Login) },
  { path: 'auth/callback', title: 'Callback', loadComponent: () => import('./features/callback/callback').then(m => m.Callback) },
  { path: '', title: 'Dashboard', canActivate: [authGuard], loadComponent: () => import('./features/dashboard/dashboard').then(m => m.Dashboard) },
  { path: 'admin/audit', title: 'Audit log', canActivate: [authGuard, adminGuard], loadComponent: () => import('./features/audit/audit').then(m => m.Audit) },
  { path: 'teams', title: 'Teams', canActivate: [authGuard], loadComponent: () => import('./features/teams/teams').then(m => m.Teams) },
  { path: 'teams/:teamId', title: 'Team detail', canActivate: [authGuard], loadComponent: () => import('./features/team-detail/team-detail').then(m => m.TeamDetail) },
  { path: 'teams/:teamId/projects', title: 'Projects', canActivate: [authGuard], loadComponent: () => import('./features/projects/projects').then(m => m.Projects) },
  { path: 'projects/:projectId', title: 'Tasks', canActivate: [authGuard], loadComponent: () => import('./features/tasks/tasks').then(m => m.Tasks) },
  { path: 'tasks/:taskId', title: 'Task detail', canActivate: [authGuard], loadComponent: () => import('./features/task-detail/task-detail').then(m => m.TaskDetail) },
  { path: 'forbidden', title: 'You do not have access', loadComponent: () => import('./features/forbidden/forbidden').then(m => m.Forbidden) },
  { path: '**', title: 'Not found', loadComponent: () => import('./features/not-found/not-found').then(m => m.NotFound) },
];
