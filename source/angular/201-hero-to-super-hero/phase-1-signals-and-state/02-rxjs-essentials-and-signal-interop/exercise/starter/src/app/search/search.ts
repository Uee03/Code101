// Starter: the stream below has two problems. After you type "boom" the search stops working for good,
// and typing the same text twice in a row sends the request twice. Fix both (TODOs 1 and 2).
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { toObservable, toSignal } from '@angular/core/rxjs-interop';
import { debounceTime, map, Observable, of, startWith, switchMap, tap } from 'rxjs';
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
  protected readonly online = signal(true);

  protected readonly state = toSignal(
    toObservable(this.query).pipe(
      debounceTime(300),
      map((text) => text.trim()),
      // TODO 1: add distinctUntilChanged() here, so the same trimmed text does not search twice in a row.
      switchMap((text): Observable<SearchState> => {
        if (text.length < 2) {
          return of(IDLE);
        }
        return this.service.search(text).pipe(
          tap(() => this.requests.update((count) => count + 1)),
          map((hits): SearchState => ({ status: 'done', hits })),
          startWith(LOADING)
          // TODO 2: add catchError after startWith that returns of({ status: 'error', hits: [], message: ... }).
          // It must sit INSIDE the switchMap, so that only this one search ends and the outer stream keeps living.
        );
      })
    ),
    { initialValue: IDLE }
  );
}
