import { Component, input, output } from '@angular/core';
import { Task } from '../task';

@Component({
  selector: 'li[app-task-item]',
  templateUrl: './task-item.html',
  styleUrl: './task-item.css',
  host: {
    '[class.done]': 'task().done'
    // TODO 2: add a second host binding: the class 'highlight' while the `highlight` input is true.
  }
})
export class TaskItem {
  readonly task = input.required<Task>();
  readonly position = input(1);
  // TODO 1: add an input `highlight` that is false unless the parent sets it (use input(false)).
  readonly toggled = output<number>();
  readonly removed = output<number>();

  protected toggle(): void {
    this.toggled.emit(this.task().id);
  }

  protected remove(): void {
    this.removed.emit(this.task().id);
  }
}
