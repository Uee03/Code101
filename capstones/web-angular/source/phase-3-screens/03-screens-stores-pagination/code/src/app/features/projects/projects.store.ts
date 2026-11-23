import { inject, Injectable } from '@angular/core';
import { Api } from '../../api/api';
import { createProject, deleteProject, getProject, listProjects, updateProject } from '../../api/functions';
import { Project, ProjectCreate } from '../../api/models';
import { Creation, CursorList, etag } from '../../core/state';
@Injectable({ providedIn: 'root' })
export class ProjectsStore extends CursorList<Project> {
  private readonly api = inject(Api);
  private readonly creation = new Creation();
  loadProjects(teamId: string, archived: boolean): Promise<void> { return this.load(cursor => this.api.invoke(listProjects, { teamId, archived, limit: 25, cursor })); }
  create(teamId: string, body: ProjectCreate): Promise<Project> { return this.creation.send(body, (key, body) => this.api.invoke(createProject, { teamId, 'Idempotency-Key': key, body })); }
  remove(projectId: string): Promise<void> { return this.api.invoke(deleteProject, { projectId }); }
  async archive(projectId: string, archived: boolean): Promise<void> {
    const current = etag(await this.api.invoke$Response(getProject, { projectId }));
    await this.api.invoke(updateProject, { projectId, 'If-Match': current.etag, body: { archived } });
  }
}
