import { Injectable } from '@angular/core';
import { map, Observable, timer } from 'rxjs';

export interface Hit {
  id: number;
  title: string;
}

const DATA: Hit[] = [
  { id: 1, title: 'Add the health check' },
  { id: 2, title: 'Write the OpenAPI file' },
  { id: 3, title: 'Seed the database' },
  { id: 4, title: 'Explain signals' },
  { id: 5, title: 'Explain RxJS' },
  { id: 6, title: 'Record a demo' }
];

@Injectable({ providedIn: 'root' })
export class SearchService {
  // A stand-in for an HTTP call: it answers after 300 ms, and fails for the query "boom".
  search(query: string): Observable<Hit[]> {
    return timer(300).pipe(
      map(() => {
        if (query.toLowerCase() === 'boom') {
          throw new Error('The search service failed.');
        }
        return DATA.filter((hit) => hit.title.toLowerCase().includes(query.toLowerCase()));
      })
    );
  }
}
