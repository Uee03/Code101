import type { ChatChunk } from "./ollama.js";

export function tokensPerSecond(final: ChatChunk & { eval_duration?: number }): number | undefined {
  if (!final.done || !final.eval_count || !final.eval_duration) {
    return undefined;
  }
  return final.eval_count / (final.eval_duration / 1e9);
}
