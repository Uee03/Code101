import { inject, Injectable, signal } from '@angular/core';
import { Api } from '../../api/api';
import { getTeam, updateTeam, listMembers, putMember, removeMember } from '../../api/functions';
import { Member, Team, TeamRole } from '../../api/models';
import { CursorList, etag, Versioned } from '../../core/state';
@Injectable({ providedIn: 'root' })
export class TeamDetailStore {
  private readonly api = inject(Api);
  readonly team = signal<Versioned<Team> | null>(null);
  readonly members = new CursorList<Member>();
  async load(id: string): Promise<void> {
    this.team.set(null);
    this.team.set(etag(await this.api.invoke$Response(getTeam, { teamId: id })));
    await this.members.load(cursor => this.api.invoke(listMembers, { teamId: id, limit: 25, cursor }));
  }
  async save(name: string, description: string): Promise<void> {
    const old = this.team()!;
    this.team.set({ value: { ...old.value, name, description }, etag: old.etag });
    try {
      this.team.set(etag(await this.api.invoke$Response(updateTeam, { teamId: old.value.id, 'If-Match': old.etag, body: { name, description } })));
    } catch (error) { this.team.set(old); throw error; }
  }
  async put(userId: string, role: TeamRole): Promise<void> {
    await this.api.invoke(putMember, { teamId: this.team()!.value.id, userId, body: { role } });
    await this.load(this.team()!.value.id);
  }
  async remove(userId: string): Promise<void> {
    await this.api.invoke(removeMember, { teamId: this.team()!.value.id, userId });
    await this.load(this.team()!.value.id);
  }
}
