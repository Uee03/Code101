import { hashSource } from './hash-source.js';

const script = 'console.log("static page");';
const first = hashSource(script);

console.log(first.startsWith("'sha256-"), first.length);
console.log(first === hashSource(script), first === hashSource(`${script} `));
