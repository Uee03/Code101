import { Pipe, PipeTransform } from '@angular/core';

@Pipe({ name: 'plural' })
export class Plural implements PipeTransform {
  // TODO 1: return "<count> <word>" and add an "s" to the word when count is not 1 (for example "1 task" and "2 tasks").
  transform(count: number, word: string): string {
    return String(count) + ' ' + word;
  }
}
