import { useEffect, useRef, useState, type FormEvent } from 'react';
import PageTitle from '../core/PageTitle';
import { useToast } from '../core/toast';
import ConfirmDialog from '../shared/ConfirmDialog';
import Icon from '../shared/Icon';

type Status = 'todo' | 'doing' | 'done';
type Task = { id: number; title: string; status: Status };

const columns: { value: Status; label: string }[] = [
  { value: 'todo', label: 'To do' },
  { value: 'doing', label: 'Doing' },
  { value: 'done', label: 'Done' },
];

const initialTasks: Task[] = [
  { id: 1, title: 'Write the release notes', status: 'todo' },
  { id: 2, title: 'Fix the login redirect', status: 'doing' },
  { id: 3, title: 'Review the pull request', status: 'doing' },
  { id: 4, title: 'Plan the sprint', status: 'done' },
];

function isStatus(value: string): value is Status {
  return value === 'todo' || value === 'doing' || value === 'done';
}

function labelOf(status: Status): string {
  return columns.find((column) => column.value === status)?.label ?? status;
}

export default function Tasks() {
  const [tasks, setTasks] = useState<Task[]>(initialTasks);
  const [title, setTitle] = useState('');
  const [error, setError] = useState('');
  const [pendingDelete, setPendingDelete] = useState<Task | null>(null);
  const toast = useToast();
  const titleInput = useRef<HTMLInputElement>(null);
  const nextId = useRef(initialTasks.length + 1);
  const focusAfterRender = useRef<string | null>(null);

  useEffect(() => {
    if (focusAfterRender.current) {
      document.getElementById(focusAfterRender.current)?.focus();
      focusAfterRender.current = null;
    }
  }, [tasks]);

  function addTask(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const clean = title.trim();
    if (clean === '') {
      setError('Enter a title.');
      titleInput.current?.focus();
      return;
    }
    setError('');
    const id = nextId.current;
    nextId.current += 1;
    setTasks((current) => [...current, { id, title: clean, status: 'todo' }]);
    setTitle('');
    toast.show(`Added "${clean}" to To do.`);
  }

  function moveTask(task: Task, status: Status) {
    focusAfterRender.current = `move-${task.id}`;
    setTasks((current) => current.map((item) => (item.id === task.id ? { ...item, status } : item)));
    toast.show(`Moved "${task.title}" to ${labelOf(status)}.`);
  }

  function confirmDelete() {
    if (!pendingDelete) {
      return;
    }
    const removed = pendingDelete;
    focusAfterRender.current = 'board-heading';
    setTasks((current) => current.filter((item) => item.id !== removed.id));
    setPendingDelete(null);
    toast.show(`Deleted "${removed.title}".`);
  }

  return (
    <>
      <PageTitle>Tasks</PageTitle>
      <section aria-labelledby="new-task-heading">
        <h2 id="new-task-heading">New task</h2>
        <form onSubmit={addTask} noValidate>
          <label htmlFor="new-title">Title</label>
          <input
            id="new-title"
            ref={titleInput}
            value={title}
            onChange={(event) => setTitle(event.target.value)}
            aria-invalid={error !== ''}
            aria-describedby={error ? 'new-title-error' : undefined}
            autoComplete="off"
          />
          {error && (
            <p id="new-title-error" className="error">
              <span className="visually-hidden">Error: </span>
              {error}
            </p>
          )}
          <button type="submit">
            <Icon name="plus" />
            Add task
          </button>
        </form>
      </section>
      <h2 id="board-heading" tabIndex={-1}>
        Board
      </h2>
      <div className="columns">
        {columns.map((column) => {
          const items = tasks.filter((task) => task.status === column.value);
          return (
            <section key={column.value} aria-labelledby={`column-${column.value}`} className="column">
              <h3 id={`column-${column.value}`}>
                {column.label} ({items.length})
              </h3>
              {items.length === 0 ? (
                <p>No tasks.</p>
              ) : (
                <ul>
                  {items.map((task) => (
                    <li key={task.id} className="card">
                      <span className="card-title">{task.title}</span>
                      <label htmlFor={`move-${task.id}`} className="visually-hidden">
                        Move {task.title} to
                      </label>
                      <select
                        id={`move-${task.id}`}
                        value={task.status}
                        onChange={(event) => {
                          const next = event.target.value;
                          if (isStatus(next)) {
                            moveTask(task, next);
                          }
                        }}
                      >
                        {columns.map((option) => (
                          <option key={option.value} value={option.value}>
                            {option.label}
                          </option>
                        ))}
                      </select>
                      <button
                        type="button"
                        className="icon-button"
                        aria-label={`Delete ${task.title}`}
                        onClick={() => setPendingDelete(task)}
                      >
                        <Icon name="x" />
                      </button>
                    </li>
                  ))}
                </ul>
              )}
            </section>
          );
        })}
      </div>
      <ConfirmDialog
        open={pendingDelete !== null}
        title="Delete this task?"
        message={pendingDelete ? `"${pendingDelete.title}" will be removed. This cannot be undone.` : ''}
        confirmLabel="Delete"
        onConfirm={confirmDelete}
        onCancel={() => setPendingDelete(null)}
      />
    </>
  );
}
