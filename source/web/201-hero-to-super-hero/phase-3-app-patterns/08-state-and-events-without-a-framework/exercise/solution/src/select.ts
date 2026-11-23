import type { Store } from "./store";

export function subscribeTo<S, A, T>(
  store: Store<S, A>,
  select: (state: S) => T,
  listener: (value: T) => void,
): () => void {
  let previous = select(store.getState());
  listener(previous);
  return store.subscribe((state) => {
    const next = select(state);
    if (!Object.is(next, previous)) {
      previous = next;
      listener(next);
    }
  });
}
