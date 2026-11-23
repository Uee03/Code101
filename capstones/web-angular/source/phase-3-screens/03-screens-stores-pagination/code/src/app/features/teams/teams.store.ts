import { inject, Injectable } from '@angular/core';
import { Api } from '../../api/api';
import { createTeam, deleteTeam, listTeams } from '../../api/functions';
import { Team } from '../../api/models';
import { Creation, CursorList } from '../../core/state';
@Injectable({ providedIn: 'root' })
export class TeamsStore extends CursorList<Team> {
  private readonly api = inject(Api);
  private readonly creation = new Creation();
  loadTeams(q = '', sort: '-createdAt' | 'createdAt' = '-createdAt'): Promise<void> {
    return this.load(cursor => this.api.invoke(listTeams, { q: q.trim() || undefined, sort, limit: 25, cursor }));
  }
  create(name: string, description: string): Promise<Team> {
    return this.creation.send({ name, description }, (key, body) => this.api.invoke(createTeam, { 'Idempotency-Key': key, body }));
  }
  remove(teamId: string): Promise<void> { return this.api.invoke(deleteTeam, { teamId }); }
}
