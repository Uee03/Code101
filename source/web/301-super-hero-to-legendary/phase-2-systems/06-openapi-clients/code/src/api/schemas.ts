import { z } from 'zod';
import type { Assignable, Expect } from './compat.js';
import type { components } from './schema.js';

export const TaskStatusSchema = z.enum(['todo', 'in_progress', 'blocked', 'done', 'cancelled']);
export const TaskPrioritySchema = z.enum(['low', 'medium', 'high', 'urgent']);

export const TaskSchema = z.object({
  id: z.uuid(),
  projectId: z.uuid(),
  title: z.string().min(1).max(200),
  description: z.string().max(10000),
  status: TaskStatusSchema,
  priority: TaskPrioritySchema,
  assigneeId: z.uuid().nullable(),
  dueDate: z.iso.date().nullable(),
  completedAt: z.iso.datetime().nullable(),
  createdBy: z.uuid(),
  version: z.number().int().min(1),
  createdAt: z.iso.datetime(),
  updatedAt: z.iso.datetime(),
});

export const TaskPageSchema = z.object({
  items: z.array(TaskSchema),
  nextCursor: z.string().nullable(),
});

export const ProblemSchema = z.object({
  type: z.string(),
  title: z.string(),
  status: z.number().int(),
  detail: z.string().optional(),
  instance: z.string().optional(),
  traceId: z.string().optional(),
  code: z.string().optional(),
});

export type Task = components['schemas']['Task'];
export type TaskUpdate = components['schemas']['TaskUpdate'];
export type Problem = components['schemas']['Problem'];

// Drift detection: if the contract changes and these hand-written schemas do not, this file stops compiling.
export type SchemaDriftChecks = [
  Expect<Assignable<z.infer<typeof TaskSchema>, Task>>,
  Expect<Assignable<z.infer<typeof TaskPageSchema>, components['schemas']['TaskPage']>>,
  Expect<Assignable<z.infer<typeof ProblemSchema>, Problem>>,
];
