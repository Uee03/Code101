import { use } from 'react';
import { loadStats } from '../stats-api';

export default function StatsPanel() {
  const stats = use(loadStats());
  return (
    <p>
      {stats.reviewers} reviewers, average review time {stats.averageDays} days.
    </p>
  );
}
