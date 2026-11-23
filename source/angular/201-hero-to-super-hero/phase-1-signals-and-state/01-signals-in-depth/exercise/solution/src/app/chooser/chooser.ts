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

  protected readonly selectedId = linkedSignal<Item[], number | null>({
    source: this.tasks,
    computation: (list, previous) => (list.some((item) => item.id === previous?.value) ? previous!.value : (list[0]?.id ?? null))
  });
  protected readonly selected = computed(() => this.tasks().find((item) => item.id === this.selectedId()) ?? null);

  protected readonly draft = linkedSignal(() => this.selected()?.title ?? '');

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
