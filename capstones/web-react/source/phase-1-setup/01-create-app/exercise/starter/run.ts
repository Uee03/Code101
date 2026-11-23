import { pageSize } from './answer';
if (pageSize !== 25) throw new Error('Use the API default page size, 25.');
console.log('exercise: page size 25');
