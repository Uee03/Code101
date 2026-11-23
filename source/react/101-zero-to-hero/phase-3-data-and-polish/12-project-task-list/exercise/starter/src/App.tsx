import { useState } from 'react';
import type { Filter, Task } from './types';
import useLocalStorage from './hooks/useLocalStorage';
import TaskForm from './components/TaskForm';
import FilterBar from './components/FilterBar';
import TaskList from './components/TaskList';

export default function App() {
  const [tasks, setTasks] = useLocalStorage<Task[]>('task-list.tasks', []);
  const [filter, setFilter] = useState<Filter>('all');

  function addTask(title: string) {
    const nextId = Math.max(0, ...tasks.map((task) => task.id)) + 1;
    setTasks([...tasks, { id: nextId, title, done: false }]);
  }

  function toggleTask(id: number) {
    setTasks(tasks.map((task) => (task.id === id ? { ...task, done: !task.done } : task)));
  }

  function deleteTask(id: number) {
    setTasks(tasks.filter((task) => task.id !== id));
  }

  // TODO 1: write function clearDone() that keeps only the tasks that are not done.

  const remaining = tasks.filter((task) => !task.done).length;
  const visible = tasks.filter((task) => {
    if (filter === 'active') {
      return !task.done;
    }
    if (filter === 'done') {
      return task.done;
    }
    return true;
  });

  return (
    <main>
      <h1>Task list</h1>
      <TaskForm onAdd={addTask} />
      <p role="status">{remaining === 1 ? '1 task left' : `${remaining} tasks left`}</p>
      <FilterBar filter={filter} onChange={setFilter} />
      <TaskList tasks={visible} onToggle={toggleTask} onDelete={deleteTask} />
      {/* TODO 2: show a button "Clear completed" that calls clearDone, only when at least one task is done. */}
    </main>
  );
}
