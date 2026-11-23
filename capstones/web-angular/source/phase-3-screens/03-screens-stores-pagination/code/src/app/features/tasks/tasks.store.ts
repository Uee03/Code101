import { inject, Injectable, signal } from '@angular/core';
import { Api } from '../../api/api';
import { createTask, getProject, listMembers, listTasks, getTask, updateTask } from '../../api/functions';
import { Member, Project, Task, TaskCreate, TaskStatus } from '../../api/models';
import { ListTasks$Params } from '../../api/fn/tasks/list-tasks';
import { Creation, CursorList, etag } from '../../core/state';
export type TaskFilter = Omit<ListTasks$Params, 'projectId' | 'limit' | 'cursor'>;
@Injectable({ providedIn: 'root' })
export class TasksStore extends CursorList<Task> {
  private readonly api = inject(Api);
  private readonly creation = new Creation();
  readonly project = signal<Project | null>(null);
  readonly members = new CursorList<Member>();
  async loadTasks(projectId: string, filter: TaskFilter): Promise<void> {
    this.project.set(null);
    const project = await this.api.invoke(getProject, { projectId });
    this.project.set(project);
    await this.members.load(cursor => this.api.invoke(listMembers, { teamId: project.teamId, limit: 25, cursor }));
    await this.load(cursor => this.api.invoke(listTasks, { projectId, limit: 25, cursor, ...filter }));
  }
  create(projectId: string, body: TaskCreate): Promise<Task> {
    return this.creation.send(body, (key, body) => this.api.invoke(createTask, { projectId, 'Idempotency-Key': key, body }));
  }
  async move(taskId: string, status: TaskStatus): Promise<void> {
    const current = etag(await this.api.invoke$Response(getTask, { taskId }));
    await this.api.invoke(updateTask, { taskId, 'If-Match': current.etag, body: { status } });
  }
}
