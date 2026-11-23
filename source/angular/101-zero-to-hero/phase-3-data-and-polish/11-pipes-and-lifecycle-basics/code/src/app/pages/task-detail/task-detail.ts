import { DatePipe, JsonPipe, TitleCasePipe } from '@angular/common';
import { Component, computed, inject, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TaskStore } from '../../task-store';

@Component({
  selector: 'app-task-detail-page',
  imports: [DatePipe, JsonPipe, RouterLink, TitleCasePipe],
  templateUrl: './task-detail.html'
})
export class TaskDetailPage {
  protected readonly store = inject(TaskStore);

  readonly id = input.required<string>();
  protected readonly task = computed(() => this.store.byId(Number(this.id())));
}
