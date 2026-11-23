import { DatePipe, TitleCasePipe } from '@angular/common';
import { Component, computed, inject, input } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { Task } from '../../task';
import { TaskStore } from '../../task-store';

@Component({
  selector: 'app-task-detail-page',
  imports: [DatePipe, RouterLink, TitleCasePipe],
  templateUrl: './task-detail.html'
})
export class TaskDetailPage {
  private readonly router = inject(Router);
  protected readonly store = inject(TaskStore);

  readonly id = input.required<string>();
  protected readonly task = computed(() => this.store.byId(Number(this.id())));

  protected remove(task: Task): void {
    this.store.remove(task.id);
    void this.router.navigateByUrl('/');
  }
}
