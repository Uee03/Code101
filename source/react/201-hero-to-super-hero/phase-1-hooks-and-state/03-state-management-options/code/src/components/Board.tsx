import { useState, type FormEvent } from 'react';
import { useCreateTask, useMoveTask, useRemoveTask, useTasks } from '../hooks/tasks';
import { isStatus, statuses, type Task } from '../tasks';
import { useUiStore } from '../ui/ui-store';
import { useView } from '../ui/view-context';

type TaskItemProps = {
  task: Task;
  onMove: (task: Task, next: string) => void;
  onRemove: (task: Task) => void;
};

function TaskItem({ task, onMove, onRemove }: TaskItemProps) {
  return (
    <li>
      {task.title} <small>({task.status})</small>
      <br />
      <select aria-label={`Move ${task.title}`} value={task.status} onChange={(event) => onMove(task, event.target.value)}>
        {statuses.map((value) => (
          <option key={value} value={value}>
            {value}
          </option>
        ))}
      </select>{' '}
      <button type="button" onClick={() => onRemove(task)}>
        Remove
      </button>
    </li>
  );
}

export default function Board() {
  const tasks = useTasks();
  const create = useCreateTask();
  const move = useMoveTask();
  const remove = useRemoveTask();
  const { view } = useView();
  const query = useUiStore((state) => state.query);
  const showToast = useUiStore((state) => state.showToast);
  const [title, setTitle] = useState('');

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const trimmed = title.trim();
    if (trimmed === '') {
      return;
    }
    create.mutate(trimmed, {
      onSuccess: () => {
        setTitle('');
        showToast('Task added');
      },
    });
  }

  function handleMove(task: Task, next: string) {
    if (isStatus(next)) {
      move.mutate({ id: task.id, status: next }, { onSuccess: () => showToast('Task moved') });
    }
  }

  function handleRemove(task: Task) {
    remove.mutate(task.id, { onSuccess: () => showToast('Task removed') });
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

  const needle = query.trim().toLowerCase();
  const visible = tasks.data.filter((task) => task.title.toLowerCase().includes(needle));

  return (
    <>
      <form onSubmit={handleSubmit}>
        <label>
          New task <input value={title} onChange={(event) => setTitle(event.target.value)} />
        </label>{' '}
        <button type="submit" disabled={create.isPending}>
          Add
        </button>
      </form>
      {visible.length === 0 && <p>No tasks match.</p>}
      {view === 'board' ? (
        <div className="board">
          {statuses.map((status) => (
            <section key={status}>
              <h2>{status}</h2>
              <ul>
                {visible
                  .filter((task) => task.status === status)
                  .map((task) => (
                    <TaskItem key={task.id} task={task} onMove={handleMove} onRemove={handleRemove} />
                  ))}
              </ul>
            </section>
          ))}
        </div>
      ) : (
        <ul>
          {visible.map((task) => (
            <TaskItem key={task.id} task={task} onMove={handleMove} onRemove={handleRemove} />
          ))}
        </ul>
      )}
    </>
  );
}
