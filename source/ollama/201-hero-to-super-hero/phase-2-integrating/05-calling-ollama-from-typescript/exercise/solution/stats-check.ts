import { tokensPerSecond } from "./stats.js";

const fast = tokensPerSecond({ done: true, eval_count: 20, eval_duration: 2_000_000_000 });
const unfinished = tokensPerSecond({ done: false, eval_count: 20, eval_duration: 2_000_000_000 });
const missing = tokensPerSecond({ done: true });

console.log(fast, unfinished, missing);
