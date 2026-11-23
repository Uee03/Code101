import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { TaskStatus } from '../api/models';

const symbols: Record<TaskStatus, string> = {
  todo: '○',
  in_progress: '◐',
  blocked: '■',
  done: '✓',
  cancelled: '✕'
};

// A status must never be shown by colour alone: it needs a text label (WCAG 2.2, 1.4.1 Use of Color).
@Component({
  selector: 'app-status-badge',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<span class="badge"><span aria-hidden="true">{{ symbol() }}</span> {{ label() }}</span>`,
  styles: `
    .badge {
      display: inline-block;
      padding: 0 0.5rem;
      border: 1px solid #4b5563;
      border-radius: 0.75rem;
    }
  `
})
export class StatusBadge {
  readonly status = input.required<TaskStatus>();

  protected readonly symbol = computed(() => symbols[this.status()]);

  protected readonly label = computed(() => {
    switch (this.status()) {
      case 'todo':
        return $localize`:@@status.todo:To do`;
      case 'in_progress':
        return $localize`:@@status.in_progress:In progress`;
      case 'blocked':
        return $localize`:@@status.blocked:Blocked`;
      case 'done':
        return $localize`:@@status.done:Done`;
      case 'cancelled':
        return $localize`:@@status.cancelled:Cancelled`;
    }
  });
}
