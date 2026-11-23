import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { toObservable, toSignal } from '@angular/core/rxjs-interop';
import { catchError, debounceTime, distinctUntilChanged, map, Observable, of, startWith, switchMap, tap } from 'rxjs';
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
}
