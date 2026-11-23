import { ChangeDetectionStrategy, Component, computed, signal } from '@angular/core';

@Component({
  selector: 'app-derived',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './derived.html',
  styleUrl: './derived.css'
})
export class Derived {
  protected readonly count = signal(0);

  protected readonly parity = computed(() => {
    console.log('parity computed');
    return this.count() % 2 === 0 ? 'even' : 'odd';
  });

  protected readonly label = computed(() => {
    console.log('label computed');
    return `${this.count()} is ${this.parity()}`;
  });

  protected readonly badge = computed(() => {
    console.log('badge computed');
    return this.parity() === 'even' ? 'E' : 'O';
  });

  protected add(amount: number): void {
    this.count.update((value) => value + amount);
  }
}
