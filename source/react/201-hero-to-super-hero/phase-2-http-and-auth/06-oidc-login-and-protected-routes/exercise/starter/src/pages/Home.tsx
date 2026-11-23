import { useMe } from '../hooks/me';
import ProblemPanel from '../shared/ProblemPanel';

export default function Home() {
  const me = useMe();
  if (me.isPending) {
    return <p role="status">Loading your profile...</p>;
  }
  if (me.isError) {
    return <ProblemPanel error={me.error} onRetry={() => void me.refetch()} />;
  }
  return (
    <section>
      <h1>Hello, {me.data.displayName}</h1>
      <p>Roles: {me.data.roles.join(', ') || 'none'}</p>
      <p>Scopes: {me.data.scopes.join(', ')}</p>
      {/* TODO: show the paragraph "You can open the audit log." only when me.data.roles includes 'admin'. */}
      <h2>My teams</h2>
      <ul>
        {me.data.teams.map((team) => (
          <li key={team.teamId}>
            {team.name} ({team.role})
          </li>
        ))}
      </ul>
    </section>
  );
}
