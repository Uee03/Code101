import { useState } from 'react';
import AppErrorBoundary from '../shared/AppErrorBoundary';

function Bomb({ explode }: { explode: boolean }) {
  if (explode) {
    throw new Error('Rendering failed on purpose');
  }
  return <p>No rendering error yet.</p>;
}

export default function CrashDemo() {
  const [explode, setExplode] = useState(false);
  return (
    <section>
      <h2>Error boundary</h2>
      <button type="button" onClick={() => setExplode(true)}>
        Break the render
      </button>
      <AppErrorBoundary onReset={() => setExplode(false)}>
        <Bomb explode={explode} />
      </AppErrorBoundary>
    </section>
  );
}
