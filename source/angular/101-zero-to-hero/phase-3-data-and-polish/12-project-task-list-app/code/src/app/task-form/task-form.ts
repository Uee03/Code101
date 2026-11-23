import { TitleCasePipe } from '@angular/common';
import { Component, inject, output } from '@angular/core';
import { NonNullableFormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Priority, TaskDraft } from '../task';

@Component({
  selector: 'app-task-form',
  imports: [ReactiveFormsModule, TitleCasePipe],
  templateUrl: './task-form.html',
  styleUrl: './task-form.css'
})
export class TaskForm {
  private readonly fb = inject(NonNullableFormBuilder);

  readonly added = output<TaskDraft>();
  protected readonly priorities: readonly Priority[] = ['low', 'normal', 'high'];
  protected readonly form = this.fb.group({
    title: ['', [Validators.required, Validators.minLength(3), Validators.maxLength(80)]],
    priority: this.fb.control<Priority>('normal'),
    due: ['']
  });
  protected readonly title = this.form.controls.title;

  protected submit(): void {
    const title = this.title.value.trim();
    if (this.form.invalid || title === '') {
      this.form.markAllAsTouched();
      return;
    }
    const { priority, due } = this.form.getRawValue();
    this.added.emit({ title, priority, due: due === '' ? undefined : due });
    this.form.reset();
  }
}
