import { ChangeDetectionStrategy, Component, ElementRef, input, output, viewChild } from '@angular/core';
import { JsonPipe } from '@angular/common';
import { Task, TaskUpdate } from '../api/models';
import { Icon } from './icon';
@Component({ selector: 'app-conflict-dialog', imports: [JsonPipe, Icon], changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<dialog #dialog aria-labelledby="conflict-title" (cancel)="close.emit()">
    <h2 id="conflict-title"><app-icon name="ui/alert-triangle" />Someone saved first</h2>
    <h3>Server version</h3><pre>{{ server() | json }}</pre><h3>Your changes</h3><pre>{{ local() | json }}</pre>
    <button autofocus (click)="choose.emit('server')">Use the server version</button>
    <button (click)="choose.emit('apply')">Apply my changes on top</button><button (click)="close.emit()">Keep editing</button>
  </dialog>` })
export class ConflictDialog {
  readonly server = input<Task | null>(null);
  readonly local = input<TaskUpdate | null>(null);
  readonly choose = output<'server' | 'apply'>();
  readonly close = output<void>();
  private readonly dialog = viewChild.required<ElementRef<HTMLDialogElement>>('dialog');
  open(): void { if (!this.dialog().nativeElement.open) this.dialog().nativeElement.showModal(); }
  dismiss(): void { this.dialog().nativeElement.close(); }
}
