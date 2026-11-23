import { inject } from '@angular/core';
import { ResolveFn } from '@angular/router';
import { Project } from '../api/models';
import { TaskService } from './task-service';

// A resolver that makes the project (key and name) available to a page before it opens.
export const projectResolver: ResolveFn<Project> = () => inject(TaskService).firstProject();
