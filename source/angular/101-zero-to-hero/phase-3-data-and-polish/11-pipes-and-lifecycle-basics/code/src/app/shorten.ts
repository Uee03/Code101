import { Pipe, PipeTransform } from '@angular/core';

@Pipe({ name: 'shorten' })
export class Shorten implements PipeTransform {
  transform(value: string, max = 30): string {
    return value.length > max ? value.slice(0, max - 3) + '...' : value;
  }
}
