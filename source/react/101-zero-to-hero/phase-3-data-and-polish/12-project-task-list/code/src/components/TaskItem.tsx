import type { Task } from '../types';
import Icon from './Icon';

type TaskItemProps = {
  task: Task;
  onToggle: (id: number) => void;
  onDelete: (id: number) => void;
};

export default function TaskItem({ task, onToggle, onDelete }: TaskItemProps) {
  return (
    <li className="task">
      <label className={task.done ? 'done' : undefined}>
        <input type="checkbox" checked={task.done} onChange={() => onToggle(task.id)} />
        {task.done && <Icon name="check-circle" />}
        <span>{task.title}</span>
      </label>
      <button type="button" aria-label={`Delete ${task.title}`} onClick={() => onDelete(task.id)}>
        <Icon name="x" />
      </button>
    </li>
  );
}
