import { useState } from 'react';

export default function useToggle(initial: boolean) {
  const [value, setValue] = useState(initial);
  function toggle() {
    setValue((current) => !current);
  }
  return [value, toggle] as const;
}
