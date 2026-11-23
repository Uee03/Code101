import { err, map, match, ok, parseJson, unwrapOr } from '../dist/index.js';

const isCount = (value) =>
  typeof value === 'object' && value !== null && typeof value.count === 'number';

const describe = {
  ok: (value) => `ok ${value}`,
  err: (error) => `err ${error.message}`,
};

const good = parseJson('{"count": 2}', isCount);
const wrongShape = parseJson('{"count": "two"}', isCount);
const broken = parseJson('{oops', isCount);

console.log(match(map(good, (value) => value.count * 10), describe));
console.log(match(wrongShape, describe));
console.log(match(broken, describe));
console.log(!broken.ok && broken.error.cause instanceof SyntaxError);
console.log(unwrapOr(ok(5), 0), unwrapOr(err('x'), 0));
