// TODO 1: write the hook. It keeps one boolean in state and returns [value, toggle].
// toggle() must flip the value (true becomes false, false becomes true).
export default function useToggle(initial: boolean) {
  return [initial, () => {}] as const;
}
