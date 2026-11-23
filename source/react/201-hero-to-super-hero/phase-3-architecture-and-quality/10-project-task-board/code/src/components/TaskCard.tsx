import { memo } from 'react';
import type { Task, TaskStatus } from '../api/types';
import { isTaskStatus, statusLabels, statuses } from '../board/columns';

type TaskCardProps = {
  task: Task;
  moving: boolean;
  onMove: (task: Task, status: TaskStatus) => void;
};

const TaskCard = memo(function TaskCard({ task, moving, onMove }: TaskCardProps) {
  const selectId = `move-${task.id}`;
  return (
    <li className="card">
      <h4>{task.title}</h4>
      <p>
        Priority: {task.priority}
        {task.dueDate ? `, due ${task.dueDate}` : ''}
      </p>
      <label htmlFor={selectId} className="visually-hidden">
        Move {task.title} to
      </label>
      <select
        id={selectId}
        value={task.status}
        aria-busy={moving}
        onChange={(event) => {
          const next = event.target.value;
          if (!moving && isTaskStatus(next)) {
            onMove(task, next);
          }
        }}
      >
        {statuses.map((status) => (
          <option key={status} value={status}>
            {statusLabels[status]}
          </option>
        ))}
      </select>
    </li>
  );
});

export default TaskCard;
