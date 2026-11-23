import { LineSplitter, parseChunk } from "./ollama.js";

function assertEqual<T>(actual: T, expected: T, label: string): void {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(`${label}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

const first = '{"done":false,"message":{"role":"assistant","content":"Hel"}}';
const second = '{"done":false,"message":{"role":"assistant","content":"lo"}}';
const last = '{"done":true,"done_reason":"stop"}';

const splitter = new LineSplitter();
assertEqual(splitter.push(`${first}\n{"done":fal`), [first], "first piece, second line still incomplete");
assertEqual(splitter.push('se,"message":{"role":"assistant","content":"lo"}}\n'), [second], "second piece completes the line");
assertEqual(splitter.push(last), [], "no newline yet");
assertEqual(splitter.flush(), [last], "flush returns the unfinished last line");
assertEqual(parseChunk('{"done":true,"done_reason":"stop","eval_count":2}').eval_count, 2, "eval_count is read");

let rejected = false;
try {
  parseChunk('{"message":{}}');
} catch {
  rejected = true;
}
assertEqual(rejected, true, "a line without done is rejected");

console.log("selftest ok: 6 checks");
