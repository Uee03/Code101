import { chat, chatStream, type ChatRequest } from "./ollama.js";

const PROMPT = "Explain in two sentences what an HTTP timeout is.";

function buildRequest(stream: boolean): ChatRequest {
  return {
    model: "llama3.2:1b",
    messages: [{ role: "user", content: PROMPT }],
    stream,
    options: { temperature: 0.2, num_predict: 200 },
  };
}

async function main(): Promise<void> {
  const signal = AbortSignal.timeout(120_000);

  console.log("--- one complete reply");
  const reply = await chat(buildRequest(false), signal);
  console.log(reply.message?.content ?? "");
  console.log(`[done_reason=${reply.done_reason} tokens=${reply.eval_count}]`);

  console.log("--- streamed reply");
  for await (const chunk of chatStream(buildRequest(true), signal)) {
    process.stdout.write(chunk.message?.content ?? "");
    if (chunk.done) {
      process.stdout.write(`\n[done_reason=${chunk.done_reason} tokens=${chunk.eval_count}]\n`);
    }
  }
}

main().catch((error: unknown) => {
  const reason = error instanceof Error ? error.message : String(error);
  console.error(`Request failed: ${reason}`);
  process.exitCode = 1;
});
