import { nextPage } from './answer';
if (nextPage(null) !== undefined) throw new Error('Stop pagination at null.');
console.log('exercise: cursor stops at null');
