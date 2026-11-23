import { useState } from 'react';
import TaskForm from './components/TaskForm';
import type { CreatedTask } from './fake-submit';

export default function App() {
  const [created, setCreated] = useState<CreatedTask[]>([]);
  return (
    <main>
      <h1>Forms lab</h1>
      <p>
        Try the titles <code>duplicate</code> (server says 422), <code>boom</code> (500) and <code>flaky</code> (the answer is lost, then
        you press the button again).
      </p>
      <TaskForm onCreated={(task) => setCreated((current) => [...current, task])} />
      <h2>Created tasks</h2>
      {created.length === 0 ? (
        <p>None yet.</p>
      ) : (
        <ul>
          {created.map((task) => (
            <li key={task.id}>
              #{task.id} {task.title} ({task.priority}
              {task.dueDate ? `, due ${task.dueDate}` : ''}){task.replayed ? ' - replayed answer, no duplicate' : ''}
            </li>
          ))}
        </ul>
      )}
    </main>
  );
}
