// TODO 1: return a helpful sentence for the status:
//   404 -> "Not found: the address may have changed."
//   429 -> "Too many requests: wait a moment and try again."
//   500 or more -> `The server had a problem (${status}). Try again later.`
//   anything else -> `The server answered ${status}`
export function httpMessage(status: number): string {
  return `The server answered ${status}`;
}
