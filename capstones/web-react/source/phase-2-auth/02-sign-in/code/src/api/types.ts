import type { components } from './schema';
export type Schemas = components['schemas'];
export type Team = Schemas['Team'];
export type Project = Schemas['Project'];
export type Task = Schemas['Task'];
export type Versioned<T> = { value: T; etag: string };
