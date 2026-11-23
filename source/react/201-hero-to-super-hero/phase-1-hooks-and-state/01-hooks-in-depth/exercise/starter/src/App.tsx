import { useReducer, useState } from 'react';
import AddTask from './components/AddTask';
import Summary from './components/Summary';
import TaskRow from './components/TaskRow';
import { countByStatus, initialTasks, tasksReducer, type Status } from './tasks';

export default function App() {
  const [tasks, dispatch] = useReducer(tasksReducer, initialTasks);
  const [note, setNote] = useState('');

  // TODO 1: wrap this calculation in useMemo, so counts keeps the same identity until tasks changes.
  const counts = countByStatus(tasks);
  // TODO 2: wrap each handler in useCallback with an empty dependency list ([]): dispatch never changes.
  const handleAdd = (title: string) => dispatch({ type: 'add', title });
  const handleMove = (id: number, status: Status) => dispatch({ type: 'move', id, status });
  const handleRemove = (id: number) => dispatch({ type: 'remove', id });

  return (
    <main>
      <h1>Hooks lab</h1>
      <AddTask onAdd={handleAdd} />
      <Summary counts={counts} />
      <ul>
        {tasks.map((task) => (
          <TaskRow key={task.id} task={task} onMove={handleMove} onRemove={handleRemove} />
        ))}
      </ul>
      <label>
        Scratch note (unrelated to the tasks) <input value={note} onChange={(event) => setNote(event.target.value)} />
      </label>
    </main>
  );
}
