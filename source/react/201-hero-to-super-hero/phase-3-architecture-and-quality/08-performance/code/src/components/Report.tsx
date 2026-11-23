import { Suspense, useMemo } from 'react';
import type { Task } from '../data';
import StatsPanel from './StatsPanel';

type ReportProps = {
  tasks: Task[];
};

export default function Report({ tasks }: ReportProps) {
  const rows = useMemo(() => {
    const byTopic = new Map<string, { total: number; done: number }>();
    for (const task of tasks) {
      const entry = byTopic.get(task.topic) ?? { total: 0, done: 0 };
      entry.total += 1;
      if (task.done) {
        entry.done += 1;
      }
      byTopic.set(task.topic, entry);
    }
    return [...byTopic.entries()].sort(([a], [b]) => a.localeCompare(b));
  }, [tasks]);

  return (
    <section aria-labelledby="report-title" className="report">
      <h2 id="report-title">Report</h2>
      <table>
        <caption>Tasks per topic</caption>
        <thead>
          <tr>
            <th scope="col">Topic</th>
            <th scope="col">Total</th>
            <th scope="col">Done</th>
          </tr>
        </thead>
        <tbody>
          {rows.map(([topic, entry]) => (
            <tr key={topic}>
              <th scope="row">{topic}</th>
              <td>{entry.total}</td>
              <td>{entry.done}</td>
            </tr>
          ))}
        </tbody>
      </table>
      <Suspense fallback={<p role="status">Loading review statistics...</p>}>
        <StatsPanel />
      </Suspense>
    </section>
  );
}
