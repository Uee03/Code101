import { Directive, effect, ElementRef, HostListener, inject, Renderer2 } from '@angular/core';
import { FormGroupDirective } from '@angular/forms';
import { Notice } from '../core/notice';
import { fieldName } from '../http/problem';
@Directive({ selector: 'form[formGroup][appFieldErrors]' })
export class FieldErrors {
  private readonly form = inject(FormGroupDirective);
  private readonly element = inject<ElementRef<HTMLFormElement>>(ElementRef);
  private readonly renderer = inject(Renderer2);
  private readonly notice = inject(Notice);
  private readonly identity = {};
  @HostListener('submit') onSubmit(): void { this.notice.activeForm = this.identity; }
  constructor() {
    effect(() => {
      const problem = this.notice.error();
      if (this.notice.activeForm !== this.identity) return;
      if (problem?.status === 409) {
        let summary = this.element.nativeElement.querySelector<HTMLElement>('[data-api-conflict]');
        if (!summary) {
          summary = this.renderer.createElement('p') as HTMLElement;
          this.renderer.setAttribute(summary, 'data-api-conflict', '');
          this.renderer.setAttribute(summary, 'role', 'alert');
          this.renderer.appendChild(this.element.nativeElement, summary);
        }
        this.renderer.setProperty(summary, 'textContent', problem.detail ?? problem.title);
      }
      for (const error of problem?.errors ?? []) {
        const name = fieldName(error.pointer);
        if (!name || !this.form.form?.get(name)) continue;
        const input = Array.from(this.element.nativeElement.querySelectorAll<HTMLElement>('[formcontrolname]'))
          .find(node => node.getAttribute('formcontrolname') === name);
        if (!input) continue;
        const id = input.id + '-api-error';
        let message = this.element.nativeElement.querySelector<HTMLElement>('#' + id);
        if (!message) {
          message = this.renderer.createElement('p') as HTMLElement;
          this.renderer.setAttribute(message, 'id', id);
          this.renderer.appendChild(input.parentElement, message);
        }
        this.renderer.setProperty(message, 'textContent', error.detail);
        const described = new Set((input.getAttribute('aria-describedby') ?? '').split(' ').filter(Boolean));
        described.add(id);
        this.renderer.setAttribute(input, 'aria-describedby', [...described].join(' '));
        this.renderer.setAttribute(input, 'aria-invalid', 'true');
        // Clear server errors on the next input, not by erasing the user's draft.
        const stop = this.renderer.listen(input, 'input', () => {
          this.renderer.removeAttribute(input, 'aria-invalid');
          this.renderer.setProperty(message, 'textContent', ''); stop();
        });
      }
    });
  }
}
