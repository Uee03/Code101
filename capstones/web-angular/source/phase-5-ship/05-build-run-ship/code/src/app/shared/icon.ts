import { ChangeDetectionStrategy, Component, input } from '@angular/core';
@Component({ selector: 'app-icon', changeDetection: ChangeDetectionStrategy.OnPush,
  host: { 'aria-hidden': 'true' },
  template: `<span class="icon" [style.mask]="'url(/icons/' + name() + '.svg) center / contain no-repeat'"></span>` })
export class Icon { readonly name = input.required<string>(); }
