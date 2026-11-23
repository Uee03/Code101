import type { Store } from "./store";

// TODO 1: call listener with select(state) once now, and again only when the selected value changes
// (compare with Object.is). Return the unsubscribe function from store.subscribe.
export function subscribeTo<S, A, T>(
  _store: Store<S, A>,
  _select: (state: S) => T,
  _listener: (value: T) => void,
): () => void {
  throw new Error("TODO 1");
}
