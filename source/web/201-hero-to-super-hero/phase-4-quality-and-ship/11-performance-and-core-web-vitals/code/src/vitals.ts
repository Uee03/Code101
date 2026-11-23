interface LayoutShiftEntry extends PerformanceEntry {
  readonly value: number;
  readonly hadRecentInput: boolean;
}

export interface VitalsOutputs {
  readonly lcp: HTMLElement;
  readonly cls: HTMLElement;
  readonly inp: HTMLElement;
}

function observe(
  type: string,
  handle: (entries: PerformanceEntry[]) => void,
  options: { durationThreshold?: number } = {},
): boolean {
  if (!PerformanceObserver.supportedEntryTypes.includes(type)) {
    return false;
  }
  const observer = new PerformanceObserver((list) => handle(list.getEntries()));
  observer.observe({ type, buffered: true, ...options });
  return true;
}

export function observeVitals(outputs: VitalsOutputs): void {
  let layoutShift = 0;
  let slowest = 0;

  const lcpSupported = observe("largest-contentful-paint", (entries) => {
    const latest = entries[entries.length - 1];
    if (latest !== undefined) {
      outputs.lcp.textContent = `${Math.round(latest.startTime)} ms`;
    }
  });
  if (!lcpSupported) {
    outputs.lcp.textContent = "not supported in this browser";
  }

  const clsSupported = observe("layout-shift", (entries) => {
    for (const entry of entries as LayoutShiftEntry[]) {
      if (!entry.hadRecentInput) {
        layoutShift += entry.value;
      }
    }
    outputs.cls.textContent = layoutShift.toFixed(3);
  });
  if (!clsSupported) {
    outputs.cls.textContent = "not supported in this browser";
  }

  const eventSupported = observe(
    "event",
    (entries) => {
      for (const entry of entries) {
        slowest = Math.max(slowest, entry.duration);
      }
      outputs.inp.textContent = `${Math.round(slowest)} ms`;
    },
    { durationThreshold: 16 },
  );
  if (!eventSupported) {
    outputs.inp.textContent = "not supported in this browser";
  }
}
