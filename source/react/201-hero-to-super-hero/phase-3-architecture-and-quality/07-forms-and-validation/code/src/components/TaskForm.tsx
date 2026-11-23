import { useEffect, useRef, useState, type FormEvent } from 'react';
import { ApiProblem } from '../api/problem';
import { submitTask, type CreatedTask } from '../fake-submit';
import { fieldErrorsFromProblem, priorities, readValues, validate, type FieldErrors } from '../forms/validate';
import ProblemPanel from '../shared/ProblemPanel';
import ErrorSummary from './ErrorSummary';
import Field from './Field';

type TaskFormProps = {
  onCreated: (task: CreatedTask) => void;
};

export default function TaskForm({ onCreated }: TaskFormProps) {
  const [errors, setErrors] = useState<FieldErrors>({});
  const [formError, setFormError] = useState<unknown>(null);
  const [pending, setPending] = useState(false);
  const summaryRef = useRef<HTMLHeadingElement>(null);
  const keyRef = useRef<string | null>(null);

  useEffect(() => {
    if (Object.keys(errors).length > 0) {
      summaryRef.current?.focus();
    }
  }, [errors]);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = event.currentTarget;
    const values = readValues(form);
    const found = validate(values);
    setFormError(null);
    if (Object.keys(found).length > 0) {
      setErrors(found);
      return;
    }
    setErrors({});
    keyRef.current ??= crypto.randomUUID();
    setPending(true);
    try {
      const task = await submitTask(values, keyRef.current);
      keyRef.current = null;
      form.reset();
      onCreated(task);
    } catch (error) {
      const uncertain = error instanceof TypeError || (error instanceof ApiProblem && error.status >= 500);
      if (!uncertain) {
        keyRef.current = null;
      }
      if (error instanceof ApiProblem && error.status === 422) {
        setErrors(fieldErrorsFromProblem(error));
      } else {
        setFormError(error);
      }
    } finally {
      setPending(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} noValidate>
      <h2>New task</h2>
      <ErrorSummary errors={errors} headingRef={summaryRef} />
      {formError !== null && <ProblemPanel error={formError} />}
      <Field name="title" label="Title" hint="Required, up to 200 characters." error={errors.title}>
        {({ id, describedBy, invalid }) => (
          <input id={id} name="title" aria-describedby={describedBy} aria-invalid={invalid} autoComplete="off" />
        )}
      </Field>
      <Field name="description" label="Description" error={errors.description}>
        {({ id, describedBy, invalid }) => (
          <textarea id={id} name="description" rows={3} aria-describedby={describedBy} aria-invalid={invalid} />
        )}
      </Field>
      <Field name="priority" label="Priority" error={errors.priority}>
        {({ id, describedBy, invalid }) => (
          <select id={id} name="priority" defaultValue="medium" aria-describedby={describedBy} aria-invalid={invalid}>
            {priorities.map((value) => (
              <option key={value} value={value}>
                {value}
              </option>
            ))}
          </select>
        )}
      </Field>
      <Field name="dueDate" label="Due date" hint="Optional. Format yyyy-mm-dd." error={errors.dueDate}>
        {({ id, describedBy, invalid }) => (
          <input id={id} name="dueDate" type="date" aria-describedby={describedBy} aria-invalid={invalid} />
        )}
      </Field>
      <button type="submit" disabled={pending}>
        {pending ? 'Saving...' : 'Create task'}
      </button>
    </form>
  );
}
