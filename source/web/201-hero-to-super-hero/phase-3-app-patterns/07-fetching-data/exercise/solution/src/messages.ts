export function httpMessage(status: number): string {
  if (status === 404) {
    return "Not found: the address may have changed.";
  }
  if (status === 429) {
    return "Too many requests: wait a moment and try again.";
  }
  if (status >= 500) {
    return `The server had a problem (${status}). Try again later.`;
  }
  return `The server answered ${status}`;
}
