export interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

export interface ChatChunk {
  message?: ChatMessage;
  done: boolean;
  done_reason?: string;
  eval_count?: number;
}

export interface ChatRequest {
  model: string;
  messages: ChatMessage[];
  stream: boolean;
  options?: { temperature?: number; num_predict?: number };
}

const BASE_URL = "http://127.0.0.1:11434";

export class LineSplitter {
  private pending = "";

  push(text: string): string[] {
    this.pending += text;
    const lines = this.pending.split("\n");
    this.pending = lines.pop() ?? "";
    return lines.filter((line) => line.trim().length > 0);
  }

  flush(): string[] {
    const rest = this.pending.trim();
    this.pending = "";
    return rest.length > 0 ? [rest] : [];
  }
}

export function parseChunk(line: string): ChatChunk {
  const value: unknown = JSON.parse(line);
  if (
    typeof value !== "object" ||
    value === null ||
    typeof (value as { done?: unknown }).done !== "boolean"
  ) {
    throw new Error("Unexpected line from Ollama: missing boolean 'done'.");
  }
  return value as ChatChunk;
}

async function post(request: ChatRequest, signal: AbortSignal): Promise<Response> {
  const response = await fetch(`${BASE_URL}/api/chat`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(request),
    signal,
  });
  if (!response.ok) {
    throw new Error(`Ollama answered HTTP ${response.status}`);
  }
  return response;
}

export async function chat(request: ChatRequest, signal: AbortSignal): Promise<ChatChunk> {
  const response = await post({ ...request, stream: false }, signal);
  return parseChunk(await response.text());
}

export async function* chatStream(
  request: ChatRequest,
  signal: AbortSignal,
): AsyncGenerator<ChatChunk> {
  const response = await post({ ...request, stream: true }, signal);
  if (response.body === null) {
    throw new Error("The response has no body to stream.");
  }
  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  const splitter = new LineSplitter();
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) {
        break;
      }
      for (const line of splitter.push(decoder.decode(value, { stream: true }))) {
        yield parseChunk(line);
      }
    }
    const tail = [...splitter.push(decoder.decode()), ...splitter.flush()];
    for (const line of tail) {
      yield parseChunk(line);
    }
  } finally {
    reader.releaseLock();
  }
}
