import type { ApiProblem } from '../api/problem';
import type { TaskCreate, TaskPriority } from '../api/types';

export type TaskValues = {
  title: string;
  description: string;
  priority: string;
  dueDate: string;
};

export type FieldName = keyof TaskValues;
export type FieldErrors = Partial<Record<FieldName, string>>;

export const priorities: readonly TaskPriority[] = ['low', 'medium', 'high', 'urgent'];

export function isPriority(value: string): value is TaskPriority {
  return (priorities as readonly string[]).includes(value);
}

export function readValues(form: HTMLFormElement): TaskValues {
  const data = new FormData(form);
  const text = (name: string) => String(data.get(name) ?? '');
  return {
    title: text('title').trim(),
    description: text('description'),
    priority: text('priority'),
    dueDate: text('dueDate'),
  };
}

export function validate(values: TaskValues): FieldErrors {
  const errors: FieldErrors = {};
  if (values.title === '') {
    errors.title = 'Enter a title.';
  } else if (values.title.length > 200) {
    errors.title = 'Use at most 200 characters.';
  }
  if (values.description.length > 10000) {
    errors.description = 'Use at most 10000 characters.';
  }
  if (!isPriority(values.priority)) {
    errors.priority = 'Choose a priority.';
  }
  if (values.dueDate !== '' && !/^\d{4}-\d{2}-\d{2}$/.test(values.dueDate)) {
    errors.dueDate = 'Use the format yyyy-mm-dd.';
  }
  return errors;
}

// Call only after validate returned no errors; the fallback keeps the types honest.
export function toCreateBody(values: TaskValues): TaskCreate {
  return {
    title: values.title,
    description: values.description,
    priority: isPriority(values.priority) ? values.priority : 'medium',
    dueDate: values.dueDate === '' ? null : values.dueDate,
  };
}

function isFieldName(value: string): value is FieldName {
  return value === 'title' || value === 'description' || value === 'priority' || value === 'dueDate';
}

export function fieldErrorsFromProblem(problem: ApiProblem): FieldErrors {
  const errors: FieldErrors = {};
  for (const item of problem.errors ?? []) {
    const name = item.pointer.replace(/^\//, '');
    if (isFieldName(name)) {
      errors[name] = item.detail;
    }
  }
  return errors;
}
