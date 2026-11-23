type AnyHandler = (payload: never) => void;

export class TypedEmitter<E extends Record<keyof E, unknown>> {
  private readonly handlers = new Map<keyof E, Set<AnyHandler>>();

  on<K extends keyof E>(event: K, handler: (payload: E[K]) => void): () => void {
    const set = this.handlers.get(event) ?? new Set<AnyHandler>();
    set.add(handler);
    this.handlers.set(event, set);
    return () => {
      set.delete(handler);
    };
  }

  emit<K extends keyof E>(event: K, payload: E[K]): void {
    for (const handler of this.handlers.get(event) ?? []) {
      // The one unavoidable cast: the map stores handlers for many events,
      // but the key K ties this handler to E[K]. It is safe because on() enforced it.
      (handler as (payload: E[K]) => void)(payload);
    }
  }
}
