import { safeReturn } from './answer';
if (safeReturn('//foreign.invalid') !== '/') throw new Error('Reject protocol-relative URLs.');
console.log('exercise: external return rejected');
