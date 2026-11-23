import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { TaskStatus } from '../api/models';

// A status must never be shown by colour alone: it needs a text label (WCAG 2.2, 1.4.1 Use of Color).
@Component({
  selector: 'app-status-badge',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<span class="badge">TODO</span>`,
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

  // TODO 1: add `protected readonly label = computed(...)` that returns a translated text for each status,
  //         written as $localize`:@@status.todo:To do` and so on (ids status.todo, status.in_progress,
  //         status.blocked, status.done, status.cancelled).
  // TODO 2: add a symbol per status (for example a check mark for done) and show it in the template with
  //         aria-hidden="true", followed by the label.
}
