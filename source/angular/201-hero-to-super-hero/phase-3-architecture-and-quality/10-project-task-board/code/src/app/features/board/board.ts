import { afterNextRender, ChangeDetectionStrategy, Component, inject, Injector, OnInit } from '@angular/core';
import { RouterLink } from '@angular/router';
import { BoardStore, COLUMNS } from '../../core/board-store';
import { ProblemView } from '../../shared/problem-view';

@Component({
  selector: 'app-board',
  imports: [RouterLink, ProblemView],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './board.html',
  styleUrl: './board.css'
})
export class Board implements OnInit {
  protected readonly store = inject(BoardStore);
  protected readonly options = COLUMNS;
  private readonly injector = inject(Injector);

  ngOnInit(): void {
    void this.store.load();
  }

  protected move(taskId: string, event: Event): void {
    const value = (event.target as HTMLSelectElement).value;
    const column = COLUMNS.find((item) => item.status === value);
    if (!column) {
      return;
    }
    void this.store.move(taskId, column.status);
    // The card jumps to another column, so its select is a new element: put keyboard focus back on it.
    afterNextRender(() => document.getElementById('move-' + taskId)?.focus(), { injector: this.injector });
  }
}
