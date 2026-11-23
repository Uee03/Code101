import { ChangeDetectionStrategy, Component, inject, OnInit, signal } from '@angular/core';
import { FakeApi } from '../fake-api';
import { TaskStore } from '../task-store';

@Component({
  selector: 'app-board',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './board.html',
  styleUrl: './board.css'
})
export class Board implements OnInit {
  protected readonly store = inject(TaskStore);
  protected readonly api = inject(FakeApi);
  protected readonly draft = signal('');

  ngOnInit(): void {
    void this.store.load();
  }

  protected setFail(checked: boolean): void {
    this.api.failSaves.set(checked);
  }

  protected async add(): Promise<void> {
    const title = this.draft().trim();
    if (title === '') {
      return;
    }
    if (await this.store.add(title)) {
      this.draft.set('');
    }
  }
}
