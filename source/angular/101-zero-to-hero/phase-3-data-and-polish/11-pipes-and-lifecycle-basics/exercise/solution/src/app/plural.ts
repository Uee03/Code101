import { Pipe, PipeTransform } from '@angular/core';

@Pipe({ name: 'plural' })
export class Plural implements PipeTransform {
  transform(count: number, word: string): string {
    return String(count) + ' ' + word + (count === 1 ? '' : 's');
  }
}
