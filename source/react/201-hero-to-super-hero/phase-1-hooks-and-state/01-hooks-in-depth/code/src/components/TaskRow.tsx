import { memo } from 'react';
import { isStatus, statuses, type Status, type Task } from '../tasks';

type TaskRowProps = {
  task: Task;
  onMove: (id: number, status: Status) => void;
  onRemove: (id: number) => void;
};

const TaskRow = memo(function TaskRow({ task, onMove, onRemove }: TaskRowProps) {
  console.log('render TaskRow', task.id);
  return (
    <li>
      {task.title} <small>({task.status})</small>{' '}
      <select
        aria-label={`Move ${task.title}`}
        value={task.status}
        onChange={(event) => {
          const next = event.target.value;
          if (isStatus(next)) {
            onMove(task.id, next);
          }
        }}
      >
        {statuses.map((status) => (
          <option key={status} value={status}>
            {status}
          </option>
        ))}
      </select>{' '}
      <button type="button" onClick={() => onRemove(task.id)}>
        Remove
      </button>
    </li>
  );
});

export default TaskRow;
