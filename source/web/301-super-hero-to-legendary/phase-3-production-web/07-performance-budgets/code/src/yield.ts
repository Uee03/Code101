type SchedulerLike = { yield?: () => Promise<void> };

// scheduler.yield() resumes your code at the front of the task queue; setTimeout is the fallback.
export function yieldToMain(): Promise<void> {
  const scheduler = (globalThis as unknown as { scheduler?: SchedulerLike }).scheduler;
  if (typeof scheduler?.yield === 'function') {
    return scheduler.yield();
  }
  return new Promise((resolve) => setTimeout(resolve, 0));
}
