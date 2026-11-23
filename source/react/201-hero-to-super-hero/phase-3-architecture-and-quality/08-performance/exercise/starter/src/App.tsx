import { Profiler, Suspense, lazy, useCallback, useDeferredValue, useMemo, useState } from 'react';
import TaskRow from './components/TaskRow';
import { makeTasks } from './data';
import { takeRowCommits } from './perf';

// TODO: load the report code before the click. Give the import a name (const loadReport = () => import('./components/Report')),
// pass it to lazy, and call it when the pointer enters or the keyboard focuses the "Show report" button.
const Report = lazy(() => import('./components/Report'));

function logRender(id: string, phase: string, actualDuration: number) {
  console.log(`[Profiler] ${id} ${phase}: ${actualDuration.toFixed(1)} ms`);
}

export default function App() {
  const [tasks, setTasks] = useState(() => makeTasks(2000));
  const [query, setQuery] = useState('');
  const [clicks, setClicks] = useState(0);
  const [showReport, setShowReport] = useState(false);
  const deferredQuery = useDeferredValue(query);

  const visible = useMemo(() => {
    const needle = deferredQuery.trim().toLowerCase();
    return tasks.filter((task) => task.title.toLowerCase().includes(needle));
  }, [tasks, deferredQuery]);

  const toggle = useCallback((id: number) => {
    setTasks((current) => current.map((task) => (task.id === id ? { ...task, done: !task.done } : task)));
  }, []);

  return (
    <main>
      <h1>Performance lab</h1>
      <p>
        <label htmlFor="query">Filter tasks </label>
        <input id="query" value={query} onChange={(event) => setQuery(event.target.value)} />
      </p>
      <p className="toolbar">
        <button type="button" onClick={() => setClicks((count) => count + 1)}>
          Count clicks ({clicks})
        </button>
        <button type="button" onClick={() => console.log('Rows committed since the last reading:', takeRowCommits())}>
          Log row commits
        </button>
        <button type="button" aria-expanded={showReport} onClick={() => setShowReport((open) => !open)}>
          {showReport ? 'Hide report' : 'Show report'}
        </button>
      </p>
      <p>
        Showing {visible.length} of {tasks.length} tasks{query !== deferredQuery ? ' (updating...)' : ''}
      </p>
      {showReport && (
        <Suspense fallback={<p role="status">Loading report...</p>}>
          <Report tasks={tasks} />
        </Suspense>
      )}
      <Profiler id="task-list" onRender={logRender}>
        <ul className="list">
          {visible.map((task) => (
            <TaskRow key={task.id} task={task} onToggle={toggle} />
          ))}
        </ul>
      </Profiler>
    </main>
  );
}
