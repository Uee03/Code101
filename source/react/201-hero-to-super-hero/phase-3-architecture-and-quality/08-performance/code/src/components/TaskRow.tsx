import { memo, useEffect } from 'react';
import type { Task } from '../data';
import { noteRowCommit } from '../perf';

type TaskRowProps = {
  task: Task;
  onToggle: (id: number) => void;
};

const TaskRow = memo(function TaskRow({ task, onToggle }: TaskRowProps) {
  useEffect(() => {
    noteRowCommit();
  });
  return (
    <li>
      <label>
        <input type="checkbox" checked={task.done} onChange={() => onToggle(task.id)} /> {task.title}
      </label>
    </li>
  );
});

export default TaskRow;
