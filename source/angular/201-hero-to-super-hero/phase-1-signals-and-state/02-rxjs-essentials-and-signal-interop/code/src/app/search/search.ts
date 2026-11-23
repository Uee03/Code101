import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { takeUntilDestroyed, toObservable, toSignal } from '@angular/core/rxjs-interop';
import { catchError, debounceTime, distinctUntilChanged, fromEvent, interval, map, merge, Observable, of, startWith, switchMap, tap } from 'rxjs';
import { Hit, SearchService } from '../search.service';

interface SearchState {
  status: 'idle' | 'loading' | 'done' | 'error';
  hits: Hit[];
  message?: string;
}

const IDLE: SearchState = { status: 'idle', hits: [] };
const LOADING: SearchState = { status: 'loading', hits: [] };

@Component({
  selector: 'app-search',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './search.html',
  styleUrl: './search.css'
})
export class Search {
  private readonly service = inject(SearchService);

  protected readonly query = signal('');
  protected readonly requests = signal(0);
  protected readonly seconds = signal(0);

  // Signal in, stream in the middle, signal out.
  protected readonly state = toSignal(
    toObservable(this.query).pipe(
      debounceTime(300),
      map((text) => text.trim()),
      distinctUntilChanged(),
      switchMap((text): Observable<SearchState> => {
        if (text.length < 2) {
          return of(IDLE);
        }
        return this.service.search(text).pipe(
          tap(() => this.requests.update((count) => count + 1)),
          map((hits): SearchState => ({ status: 'done', hits })),
          startWith(LOADING),
          catchError((error: unknown) =>
            of<SearchState>({ status: 'error', hits: [], message: error instanceof Error ? error.message : 'The search failed.' })
          )
        );
      })
    ),
    { initialValue: IDLE }
  );

  // Browser events as a stream, shown as a signal. requireSync is allowed because startWith emits at once.
  protected readonly online = toSignal(
    merge(
      fromEvent(window, 'online').pipe(map(() => true)),
      fromEvent(window, 'offline').pipe(map(() => false))
    ).pipe(startWith(navigator.onLine)),
    { requireSync: true }
  );

  constructor() {
    // A manual subscription must be ended: takeUntilDestroyed does it when the component is destroyed.
    interval(1000)
      .pipe(takeUntilDestroyed())
      .subscribe(() => this.seconds.update((count) => count + 1));
  }
}
