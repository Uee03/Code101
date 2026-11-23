import { AsyncPipe, DatePipe } from '@angular/common';
import { Component, OnDestroy, OnInit, signal } from '@angular/core';
import { map, timer } from 'rxjs';

@Component({
  selector: 'app-clock',
  imports: [AsyncPipe, DatePipe],
  templateUrl: './clock.html',
  styleUrl: './clock.css'
})
export class Clock implements OnInit, OnDestroy {
  protected readonly manual = signal(new Date());
  protected readonly automatic = timer(0, 1000).pipe(map(() => new Date()));
  private timerId: ReturnType<typeof setInterval> | undefined;

  ngOnInit(): void {
    this.timerId = setInterval(() => this.manual.set(new Date()), 1000);
  }

  ngOnDestroy(): void {
    clearInterval(this.timerId);
  }
}
