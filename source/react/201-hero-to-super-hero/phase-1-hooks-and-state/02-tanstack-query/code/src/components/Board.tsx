import { useState, type FormEvent } from 'react';
import { useCreateTask, useMoveTask, useRemoveTask, useTasks } from '../hooks/tasks';
import { isStatus, statuses } from '../tasks';

export default function Board() {
  const tasks = useTasks();
  const create = useCreateTask();
  const move = useMoveTask();
  const remove = useRemoveTask();
  const [title, setTitle] = useState('');

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const trimmed = title.trim();
    if (trimmed === '') {
      return;
    }
    create.mutate(trimmed, { onSuccess: () => setTitle('') });
  }

  if (tasks.isPending) {
    return <p role="status">Loading tasks...</p>;
  }
  if (tasks.isError) {
    return (
      <div role="alert">
        <p>{tasks.error.message}</p>
        <button type="button" onClick={() => void tasks.refetch()}>
          Try again
        </button>
      </div>
    );
  }

  return (
    <>
      <form onSubmit={handleSubmit}>
        <label>
          New task <input value={title} onChange={(event) => setTitle(event.target.value)} />
        </label>{' '}
        <button type="submit" disabled={create.isPending}>
          {create.isPending ? 'Saving...' : 'Add'}
        </button>
      </form>
      {move.isError && <p role="alert">Could not move the task: {move.error.message}. The board went back.</p>}
      <p>{tasks.isFetching ? 'Updating...' : 'Up to date'}</p>
      <div className="board">
        {statuses.map((status) => (
          <section key={status}>
            <h2>{status}</h2>
            <ul>
              {tasks.data
                .filter((task) => task.status === status)
                .map((task) => (
                  <li key={task.id}>
                    {task.title}
                    <br />
                    <select
                      aria-label={`Move ${task.title}`}
                      value={task.status}
                      onChange={(event) => {
                        const next = event.target.value;
                        if (isStatus(next)) {
                          move.mutate({ id: task.id, status: next });
                        }
                      }}
                    >
                      {statuses.map((value) => (
                        <option key={value} value={value}>
                          {value}
                        </option>
                      ))}
                    </select>{' '}
                    <button type="button" onClick={() => remove.mutate(task.id)}>
                      Remove
                    </button>
                  </li>
                ))}
            </ul>
          </section>
        ))}
      </div>
    </>
  );
}
