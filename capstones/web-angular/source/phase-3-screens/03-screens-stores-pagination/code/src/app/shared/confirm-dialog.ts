import { ChangeDetectionStrategy, Component, ElementRef, viewChild } from '@angular/core';
@Component({ selector: 'app-confirm-dialog', changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<dialog #dialog aria-labelledby="confirm-title" (cancel)="finish(false)">
    <h2 id="confirm-title">Delete this item?</h2><p>This cannot be undone.</p>
    <button autofocus (click)="finish(false)">Cancel</button><button (click)="finish(true)">Delete</button>
  </dialog>` })
export class ConfirmDialog {
  private readonly dialog = viewChild.required<ElementRef<HTMLDialogElement>>('dialog');
  private resolve?: (value: boolean) => void;
  ask(): Promise<boolean> { this.dialog().nativeElement.showModal(); return new Promise(resolve => { this.resolve = resolve; }); }
  protected finish(value: boolean): void { this.dialog().nativeElement.close(); this.resolve?.(value); }
}
