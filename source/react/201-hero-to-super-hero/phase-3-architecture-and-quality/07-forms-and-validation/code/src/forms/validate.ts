import type { ApiProblem } from '../api/problem';

export type TaskValues = {
  title: string;
  description: string;
  priority: string;
  dueDate: string;
};

export type FieldName = keyof TaskValues;
export type FieldErrors = Partial<Record<FieldName, string>>;

export const priorities = ['low', 'medium', 'high', 'urgent'] as const;

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
  if (!(priorities as readonly string[]).includes(values.priority)) {
    errors.priority = 'Choose a priority.';
  }
  if (values.dueDate !== '' && !/^\d{4}-\d{2}-\d{2}$/.test(values.dueDate)) {
    errors.dueDate = 'Use the format yyyy-mm-dd.';
  }
  return errors;
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
