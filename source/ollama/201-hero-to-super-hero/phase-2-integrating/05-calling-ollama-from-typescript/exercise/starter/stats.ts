import type { ChatChunk } from "./ollama.js";

export function tokensPerSecond(final: ChatChunk & { eval_duration?: number }): number | undefined {
  // TODO 1: return undefined unless final.done is true and both eval_count and eval_duration are present and non-zero
  // TODO 2: otherwise return eval_count divided by (eval_duration in nanoseconds / 1e9)
  return undefined;
}
