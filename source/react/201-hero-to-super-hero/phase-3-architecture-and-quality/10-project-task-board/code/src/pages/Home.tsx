import { Link } from 'react-router';
import type { Me } from '../api/types';
import PageTitle from '../core/PageTitle';
import { useMe } from '../hooks/me';
import { useTeamProjects } from '../hooks/projects';
import ProblemPanel from '../shared/ProblemPanel';

type TeamProjectsProps = {
  team: Me['teams'][number];
};

function TeamProjects({ team }: TeamProjectsProps) {
  const projects = useTeamProjects(team.teamId);
  return (
    <section aria-labelledby={`team-${team.teamId}`}>
      <h2 id={`team-${team.teamId}`}>
        {team.name} ({team.role})
      </h2>
      {projects.isPending && <p role="status">Loading projects...</p>}
      {projects.isError && <ProblemPanel error={projects.error} onRetry={() => void projects.refetch()} />}
      {projects.data &&
        (projects.data.items.length === 0 ? (
          <p>No projects yet.</p>
        ) : (
          <ul>
            {projects.data.items.map((project) => (
              <li key={project.id}>
                <Link to={`/projects/${project.id}`}>
                  {project.key}: {project.name}
                </Link>
              </li>
            ))}
          </ul>
        ))}
    </section>
  );
}

export default function Home() {
  const me = useMe();
  if (me.isPending) {
    return <p role="status">Loading your profile...</p>;
  }
  if (me.isError) {
    return <ProblemPanel error={me.error} onRetry={() => void me.refetch()} />;
  }
  return (
    <>
      <PageTitle>My teams</PageTitle>
      <p>Hello, {me.data.displayName}. Choose a project to open its board.</p>
      {me.data.teams.length === 0 ? (
        <p>You are not a member of any team yet.</p>
      ) : (
        me.data.teams.map((team) => <TeamProjects key={team.teamId} team={team} />)
      )}
    </>
  );
}
