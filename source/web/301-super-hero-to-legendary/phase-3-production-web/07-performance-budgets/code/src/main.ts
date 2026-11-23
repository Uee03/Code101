import { observeLongFrames } from './long-tasks';
import { processBlocking, processYielding, ROWS } from './work';

const status = document.querySelector<HTMLElement>('#status');
const blocking = document.querySelector<HTMLButtonElement>('#run-blocking');
const yielding = document.querySelector<HTMLButtonElement>('#run-yielding');

if (!status || !blocking || !yielding) {
  throw new Error('index.html is missing an element this script needs');
}

let running = false;

blocking.addEventListener('click', () => {
  if (running) {
    return;
  }
  // This text will not appear before the loop finishes: the browser cannot paint while the loop runs.
  status.textContent = 'Working...';
  const checksum = processBlocking(ROWS);
  status.textContent = `Blocking run done: ${ROWS} rows, checksum ${checksum}`;
});

async function runYielding(): Promise<void> {
  if (running || !status) {
    return;
  }
  running = true;
  status.textContent = 'Working...';
  const checksum = await processYielding(ROWS);
  status.textContent = `Yielding run done: ${ROWS} rows, checksum ${checksum}`;
  running = false;
}

yielding.addEventListener('click', () => {
  void runYielding();
});

observeLongFrames((entry) => {
  console.log(`[long frame] started ${Math.round(entry.startTime)} ms, lasted ${Math.round(entry.duration)} ms`);
});

// Load the measurement code after the page is interactive, in its own chunk.
function startVitals(): void {
  void import('./vitals').then(({ reportVitals }) => {
    reportVitals((report) => console.log('[vitals]', JSON.stringify(report)));
  });
}

addEventListener('load', () => {
  if ('requestIdleCallback' in window) {
    requestIdleCallback(startVitals);
  } else {
    setTimeout(startVitals, 200);
  }
});
