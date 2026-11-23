import { Project } from '../api/models';
import { ResolveFn } from '@angular/router';

// A resolver that makes the project (key and name) available to a page before it opens.
export const projectResolver: ResolveFn<Project> = () => {
  // TODO 1: inject TaskService (from './task-service') and return its firstProject() Promise.
  throw new Error('TODO: write projectResolver');
};
