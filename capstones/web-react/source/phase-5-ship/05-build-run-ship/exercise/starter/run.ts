import { signInPort } from './answer';
if (signInPort !== 5173) throw new Error('Use the registered origin port.');
console.log('exercise: sign-in port 5173');
