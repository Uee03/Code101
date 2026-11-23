import { sameTag } from './answer';
if (sameTag('"3"') !== '"3"') throw new Error('Keep the quotes.');
console.log('exercise: ETag quotes kept');
