import { Component, output, signal } from '@angular/core';
import { FormsModule, NgForm } from '@angular/forms';

@Component({
  selector: 'app-new-task-template',
  imports: [FormsModule],
  templateUrl: './new-task-template.html',
  styleUrl: './new-task-template.css'
})
export class NewTaskTemplate {
  readonly added = output<string>();
  protected readonly title = signal('');

  protected submit(form: NgForm): void {
    const value = this.title().trim();
    if (form.invalid || value === '') {
      return;
    }
    this.added.emit(value);
    form.resetForm({ title: '' });
  }
}
