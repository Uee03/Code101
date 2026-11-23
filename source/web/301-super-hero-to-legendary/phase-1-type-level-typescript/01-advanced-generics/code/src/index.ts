import { TypedEmitter } from './emitter.js';
import { defineKeys, oneOf } from './types.js';

interface TaskEvents {
  created: { id: string; title: string };
  completed: { id: string; by: string };
}

const emitter = new TypedEmitter<TaskEvents>();
const log: string[] = [];

const stopListening = emitter.on('created', (payload) => log.push(`created ${payload.title}`));
emitter.on('completed', (payload) => log.push(`completed ${payload.id} by ${payload.by}`));

emitter.emit('created', { id: 't1', title: 'Write ADR' });
emitter.emit('completed', { id: 't1', by: 'ada' });
stopListening();
emitter.emit('created', { id: 't2', title: 'Never logged' });

console.log(log.join('\n'));

const statuses = defineKeys(['todo', 'done']);
const picked = oneOf(statuses, 'done');
console.log(`${statuses.length} statuses, picked ${picked}`);
