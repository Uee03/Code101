import { yieldToMain } from './yield';

export const ROWS = 20_000;
const STEPS_PER_ROW = 2_000;
const MODULUS = 1_000_003;

// Deterministic CPU work standing in for "parse, filter and sort a big response".
function rowCost(index: number): number {
  let value = index;
  for (let step = 0; step < STEPS_PER_ROW; step += 1) {
    value = (value * 31 + step) % MODULUS;
  }
  return value;
}

// One long task: the page cannot respond to input, or paint, until the loop ends.
export function processBlocking(rows: number): number {
  let checksum = 0;
  for (let index = 0; index < rows; index += 1) {
    checksum = (checksum + rowCost(index)) % MODULUS;
  }
  return checksum;
}

// Same result, many short tasks: between chunks the browser can handle input and paint.
export async function processYielding(rows: number, chunk = 500): Promise<number> {
  let checksum = 0;
  for (let index = 0; index < rows; index += 1) {
    checksum = (checksum + rowCost(index)) % MODULUS;
    if ((index + 1) % chunk === 0) {
      await yieldToMain();
    }
  }
  return checksum;
}
