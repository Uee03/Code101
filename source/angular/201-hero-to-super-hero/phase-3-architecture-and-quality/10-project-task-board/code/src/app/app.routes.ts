import { Routes } from '@angular/router';
import { environment } from '../environments/environment';
import { authGuard } from './auth/guards';
import { taskResolver, tasksResolver } from './tasks/task.resolvers';

// Without sign-in the routes have no guard; with sign-in every page except the login pages needs one.
const protect = environment.authEnabled ? [authGuard] : [];

const authRoutes: Routes = environment.authEnabled
  ? [
      { path: 'login', title: 'Sign in', loadComponent: () => import('./features/login/login').then((m) => m.Login) },
      { path: 'auth/callback', title: 'Signing in', loadComponent: () => import('./features/callback/callback').then((m) => m.Callback) },
      { path: 'forbidden', title: 'No access', loadComponent: () => import('./features/forbidden/forbidden').then((m) => m.Forbidden) }
    ]
  : [];

export const routes: Routes = [
  { path: '', pathMatch: 'full', redirectTo: 'board' },
  {
    path: 'board',
    title: $localize`:@@title.board:Board`,
    canActivate: protect,
    loadComponent: () => import('./features/board/board').then((m) => m.Board)
  },
  {
    path: 'tasks',
    title: $localize`:@@title.tasks:Tasks`,
    canActivate: protect,
    resolve: { page: tasksResolver },
    loadComponent: () => import('./features/tasks/tasks').then((m) => m.Tasks)
  },
  {
    path: 'tasks/new',
    title: $localize`:@@title.new:New task`,
    canActivate: protect,
    loadComponent: () => import('./features/new-task/new-task').then((m) => m.NewTask)
  },
  {
    path: 'tasks/:taskId',
    title: 'Task',
    canActivate: protect,
    resolve: { detail: taskResolver },
    loadComponent: () => import('./features/task-detail/task-detail').then((m) => m.TaskDetail)
  },
  {
    path: 'explorer',
    title: $localize`:@@title.explorer:API explorer`,
    canActivate: protect,
    loadComponent: () => import('./features/explorer/explorer').then((m) => m.Explorer)
  },
  ...authRoutes,
  {
    path: 'not-found',
    title: 'Not found',
    data: { heading: 'Not found', text: 'We could not find that page or task.' },
    loadComponent: () => import('./features/notice/notice').then((m) => m.Notice)
  },
  {
    path: 'unavailable',
    title: 'Unavailable',
    data: { heading: 'Something went wrong', text: 'The API did not answer. Check that it is running, then try again.' },
    loadComponent: () => import('./features/notice/notice').then((m) => m.Notice)
  },
  { path: '**', redirectTo: 'not-found' }
];
