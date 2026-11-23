import { Routes } from '@angular/router';
import { Explorer } from './features/explorer/explorer';
import { NewTask } from './features/new-task/new-task';

export const routes: Routes = [
  { path: '', component: Explorer, title: 'API explorer' },
  { path: 'tasks/new', component: NewTask, title: 'New task' },
  { path: '**', redirectTo: '' }
];
