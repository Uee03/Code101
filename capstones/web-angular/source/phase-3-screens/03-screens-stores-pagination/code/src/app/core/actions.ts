import { inject, Injectable } from '@angular/core';
import { Connectivity } from './connectivity';
import { Notice } from './notice';
@Injectable({ providedIn: 'root' })
export class Actions {
  private readonly notice = inject(Notice);
  private readonly connection = inject(Connectivity);
  private lastRead?: () => Promise<unknown>;
  async retry(): Promise<void> { this.connection.online.set(navigator.onLine); if (this.lastRead) await this.run(this.lastRead); }
  async run(work: () => Promise<unknown>, write = false): Promise<boolean> {
    if (!write) this.lastRead = work;
    if (write && !this.connection.online()) { this.notice.fail({ status: 0 }); return false; }
    try { await work(); if (write) this.notice.success('Saved'); return true; }
    catch (error) { this.notice.fail(error); return false; }
  }
}
