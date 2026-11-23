import { describe, labelFor } from './exhaustive.js';
import { camelizeKeys } from './keys.js';
import { href, matchRoute } from './routes.js';

console.log(href('home'));
console.log(href('team', { teamId: 't 1' }));
console.log(href('project', { teamId: 'core', projectId: 'p/9' }));
console.log(JSON.stringify(matchRoute('/teams/core/projects/p%2F9')));
console.log(matchRoute('/nope'));
console.log(describe({ type: 'status_changed', id: 't1', to: 'blocked' }));
console.log(labelFor('archived'));
console.log(JSON.stringify(camelizeKeys({ due_date: '2026-12-01', assigned_to_id: null })));
