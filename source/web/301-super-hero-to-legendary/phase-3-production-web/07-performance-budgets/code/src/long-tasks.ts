// Long tasks (older API) and long animation frames (newer, more detail) tell you the main thread was busy.
export interface LongFrameReport {
  startTime: number;
  duration: number;
}

export function observeLongFrames(report: (entry: LongFrameReport) => void): () => void {
  const supported = PerformanceObserver.supportedEntryTypes;
  const type = supported.includes('long-animation-frame') ? 'long-animation-frame' : 'longtask';
  if (!supported.includes(type)) {
    return () => {};
  }
  const observer = new PerformanceObserver((list) => {
    for (const entry of list.getEntries()) {
      report({ startTime: entry.startTime, duration: entry.duration });
    }
  });
  observer.observe({ type, buffered: true });
  return () => observer.disconnect();
}
