import { TypedEmitter } from './emitter.js';
import type {
  CanAssign,
  Consumer,
  DeepReadonly,
  ElementOf,
  Equal,
  Expect,
  IsNever,
  MethodsOf,
  Mutable,
  Producer,
  RequireAtLeastOne,
} from './types.js';
import { oneOf } from './types.js';

type Contact = { email?: string; phone?: string };
type Service = { id: string; save: () => void; load: () => number };

// Every entry must be true, otherwise tsc reports an error on that line.
export type TypeTests = [
  Expect<Equal<Mutable<{ readonly a: 1; readonly b: 2 }>, { a: 1; b: 2 }>>,
  Expect<Equal<DeepReadonly<{ a: { b: number[] } }>, { readonly a: { readonly b: readonly number[] } }>>,
  Expect<Equal<ElementOf<string[] | number[]>, string | number>>,
  Expect<Equal<IsNever<never>, true>>,
  Expect<Equal<IsNever<string>, false>>,
  Expect<Equal<MethodsOf<Service>, { save: () => void; load: () => number }>>,
  Expect<Equal<CanAssign<{ email: string }, RequireAtLeastOne<Contact>>, true>>,
  Expect<Equal<CanAssign<{}, RequireAtLeastOne<Contact>>, false>>,
  Expect<Equal<CanAssign<Producer<'a'>, Producer<string>>, true>>,
  Expect<Equal<CanAssign<Producer<string>, Producer<'a'>>, false>>,
  Expect<Equal<CanAssign<Consumer<string>, Consumer<'a'>>, true>>,
  Expect<Equal<CanAssign<Consumer<'a'>, Consumer<string>>, false>>,
];

type Events = {
  'task.created': { id: string; title: string };
  'task.deleted': { id: string };
};

// Negative tests: each directive below must hide exactly one real error.
// If the types ever stop rejecting the line, the directive itself becomes an error.
export function negativeTests(): void {
  const emitter = new TypedEmitter<Events>();
  emitter.on('task.created', (payload) => payload.title);
  // @ts-expect-error task.deleted has no title
  emitter.on('task.deleted', (payload) => payload.title);
  // @ts-expect-error unknown event name
  emitter.emit('task.updated', { id: 'x' });
  // @ts-expect-error title is missing
  emitter.emit('task.created', { id: 'x' });
  // @ts-expect-error 'medium' is not one of the options
  oneOf(['low', 'high'], 'medium');
}
