import { inject, Injectable, signal } from '@angular/core';
import { Api } from '../../api/api';
import { getTask, getProject, updateTask, completeTask, reassignTask, deleteTask, listComments, createComment, deleteComment, listMembers } from '../../api/functions';
import { Comment, Member, Task, TaskUpdate } from '../../api/models';
import { ApiProblem } from '../../http/problem';
import { StrictHttpResponse } from '../../api/strict-http-response';
import { Creation, CursorList, etag, Versioned } from '../../core/state';
@Injectable({ providedIn: 'root' })
export class TaskDetailStore {
  private readonly api = inject(Api);
  private readonly creation = new Creation();
  readonly task = signal<Versioned<Task> | null>(null);
  readonly teamId = signal('');
  readonly comments = new CursorList<Comment>();
  readonly members = new CursorList<Member>();
  readonly saving = signal(false);
  readonly conflict = signal<{ server: Task; local: TaskUpdate } | null>(null);
  async load(id: string): Promise<void> {
    this.task.set(null);
    this.task.set(etag(await this.api.invoke$Response(getTask, { taskId: id })));
    const project = await this.api.invoke(getProject, { projectId: this.task()!.value.projectId });
    this.teamId.set(project.teamId);
    await this.members.load(cursor => this.api.invoke(listMembers, { teamId: project.teamId, limit: 25, cursor }));
    await this.comments.load(cursor => this.api.invoke(listComments, { taskId: id, limit: 25, cursor }));
  }
  save(body: TaskUpdate): Promise<void> {
    const old = this.task()!;
    return this.optimistic(body, () => this.api.invoke$Response(updateTask, { taskId: old.value.id, 'If-Match': old.etag, body }));
  }
  private async optimistic(body: TaskUpdate, change: () => Promise<StrictHttpResponse<Task>>): Promise<void> {
    const old = this.task()!;
    this.saving.set(true);
    this.task.set({ value: { ...old.value, ...body } as Task, etag: old.etag });
    try {
      this.task.set(etag(await change()));
      this.conflict.set(null);
    } catch (error) {
      this.task.set(old);
      if ((error as ApiProblem).status === 412) {
        const server = await this.api.invoke(getTask, { taskId: old.value.id });
        this.conflict.set({ server, local: { ...body } });
      }
      throw error;
    } finally { this.saving.set(false); }
  }
  async resolve(choice: 'server' | 'apply'): Promise<void> {
    const local = this.conflict()!.local;
    this.task.set(etag(await this.api.invoke$Response(getTask, { taskId: this.task()!.value.id })));
    if (choice === 'apply') await this.save(local);
    this.conflict.set(null);
  }
  async revalidate(): Promise<void> {
    const old = this.task();
    if (!old || this.saving() || this.conflict()) return;
    try { this.task.set(etag(await this.api.invoke$Response(getTask, { taskId: old.value.id, 'If-None-Match': old.etag }))); }
    catch (error) { if ((error as { status?: number }).status !== 304) throw error; }
  }
  async complete(): Promise<void> {
    const old = this.task()!;
    await this.optimistic({ status: 'done' }, () => this.api.invoke$Response(completeTask, { taskId: old.value.id, 'If-Match': old.etag }));
  }
  async reassign(assigneeId: string | null): Promise<void> {
    const old = this.task()!;
    await this.optimistic({ assigneeId }, () => this.api.invoke$Response(reassignTask, { taskId: old.value.id, 'If-Match': old.etag, body: { assigneeId } }));
  }
  remove(): Promise<void> { return this.api.invoke(deleteTask, { taskId: this.task()!.value.id, 'If-Match': this.task()!.etag }); }
  async comment(body: string): Promise<void> {
    const taskId = this.task()!.value.id;
    await this.creation.send({ body }, (key, body) => this.api.invoke(createComment, { taskId, 'Idempotency-Key': key, body }));
    await this.comments.load(cursor => this.api.invoke(listComments, { taskId, limit: 25, cursor }));
    while (this.comments.state().nextCursor) await this.comments.more();
  }
  async removeComment(commentId: string): Promise<void> {
    await this.api.invoke(deleteComment, { commentId });
    this.comments.state.update(s => ({ ...s, items: s.items.filter(c => c.id !== commentId) }));
  }
}
