import { ChangeDetectionStrategy, Component, computed, linkedSignal, signal } from '@angular/core';
import { Item, PROJECTS } from '../data';

@Component({
  selector: 'app-chooser',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './chooser.html',
  styleUrl: './chooser.css'
})
export class Chooser {
  protected readonly projects = PROJECTS;
  protected readonly projectId = signal(PROJECTS[0].id);
  protected readonly tasks = computed(() => PROJECTS.find((project) => project.id === this.projectId())?.tasks ?? []);

  // TODO 1: this plain signal never resets when the project changes, so it can point at a task that is gone.
  // Replace it with linkedSignal<Item[], number | null>({ source: this.tasks, computation: ... }) that keeps the previous
  // choice when it is still in the list and otherwise falls back to the first task (or null for an empty list).
  protected readonly selectedId = signal<number | null>(PROJECTS[0].tasks[0].id);
  protected readonly selected = computed(() => this.tasks().find((item) => item.id === this.selectedId()) ?? null);

  // TODO 2: make `draft` a linkedSignal that starts as the selected title and resets when another task is chosen.
  protected readonly draft = signal('');

  protected chooseProject(value: string): void {
    this.projectId.set(Number(value));
  }

  protected chooseTask(value: string): void {
    this.selectedId.set(Number(value));
  }

  protected edit(value: string): void {
    this.draft.set(value);
  }
}
