import { useCallback, useEffect, useMemo, useRef } from 'react';
import { useParams } from 'react-router';
import type { Task, TaskStatus } from '../api/types';
import { groupByStatus, statusLabels, statuses } from '../board/columns';
import NewTaskForm from '../components/NewTaskForm';
import TaskCard from '../components/TaskCard';
import PageTitle from '../core/PageTitle';
import { useToast } from '../core/toast';
import { useProject } from '../hooks/projects';
import { useMoveTask, useTasks } from '../hooks/tasks';
import ProblemPanel from '../shared/ProblemPanel';
import NotFound from './NotFound';

export default function Board() {
  const { projectId } = useParams();
  return projectId ? <BoardView projectId={projectId} /> : <NotFound />;
}

function BoardView({ projectId }: { projectId: string }) {
  const project = useProject(projectId);
  const tasks = useTasks(projectId);
  const move = useMoveTask(projectId);
  const toast = useToast();
  const { mutate } = move;
  const focusAfterRender = useRef<string | null>(null);

  const items = useMemo(() => tasks.data?.pages.flatMap((page) => page.items) ?? [], [tasks.data]);
  const groups = useMemo(() => groupByStatus(items), [items]);

  // A moved card is a new element in another column, so focus must be put back on its select.
  useEffect(() => {
    if (focusAfterRender.current) {
      document.getElementById(focusAfterRender.current)?.focus();
      focusAfterRender.current = null;
    }
  }, [tasks.data]);

  const onMove = useCallback(
    (task: Task, status: TaskStatus) => {
      focusAfterRender.current = `move-${task.id}`;
      mutate(
        { task, status },
        { onSuccess: () => toast.show(`Moved "${task.title}" to ${statusLabels[status]}.`) },
      );
    },
    [mutate, toast],
  );

  if (project.isError) {
    return <ProblemPanel error={project.error} onRetry={() => void project.refetch()} />;
  }

  return (
    <>
      <PageTitle>{project.data?.name ?? 'Project board'}</PageTitle>
      {project.data && (
        <p>
          Project {project.data.key}. {project.data.description}
        </p>
      )}
      <NewTaskForm projectId={projectId} />
      {move.isError && <ProblemPanel error={move.error} />}
      <h2 id="board-heading">Board</h2>
      {tasks.isPending && <p role="status">Loading tasks...</p>}
      {tasks.isError && <ProblemPanel error={tasks.error} onRetry={() => void tasks.refetch()} />}
      {tasks.data && (
        <>
          <p>{items.length} tasks loaded.</p>
          <div className="columns">
            {statuses.map((status) => (
              <section key={status} aria-labelledby={`column-${status}`} className="column">
                <h3 id={`column-${status}`}>{statusLabels[status]}</h3>
                {groups[status].length === 0 ? (
                  <p>No tasks.</p>
                ) : (
                  <ul>
                    {groups[status].map((task) => (
                      <TaskCard
                        key={task.id}
                        task={task}
                        moving={move.isPending && move.variables?.task.id === task.id}
                        onMove={onMove}
                      />
                    ))}
                  </ul>
                )}
              </section>
            ))}
          </div>
          {tasks.hasNextPage && (
            <button type="button" onClick={() => void tasks.fetchNextPage()} disabled={tasks.isFetchingNextPage}>
              {tasks.isFetchingNextPage ? 'Loading...' : 'Load more tasks'}
            </button>
          )}
        </>
      )}
    </>
  );
}
