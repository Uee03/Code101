export interface AppEvents {
  "task:added": { title: string };
  "task:removed": { id: number };
}

export function emit<K extends keyof AppEvents>(
  target: EventTarget,
  name: K,
  detail: AppEvents[K],
): void {
  target.dispatchEvent(new CustomEvent(name, { detail, bubbles: true }));
}

export function on<K extends keyof AppEvents>(
  target: EventTarget,
  name: K,
  handler: (detail: AppEvents[K]) => void,
): () => void {
  const listener = (event: Event): void => {
    handler((event as CustomEvent<AppEvents[K]>).detail);
  };
  target.addEventListener(name, listener);
  return () => target.removeEventListener(name, listener);
}
