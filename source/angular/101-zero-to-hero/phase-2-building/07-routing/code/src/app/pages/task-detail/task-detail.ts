import { Component, computed, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { INITIAL_TASKS } from '../../task-data';

@Component({
  selector: 'app-task-detail-page',
  imports: [RouterLink],
  templateUrl: './task-detail.html'
})
export class TaskDetailPage {
  readonly id = input.required<string>();
  protected readonly task = computed(() => INITIAL_TASKS.find((task) => task.id === Number(this.id())));
}
