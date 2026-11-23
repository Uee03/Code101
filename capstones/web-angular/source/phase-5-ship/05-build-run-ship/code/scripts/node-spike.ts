import { nodeClient } from './node-client';
const client = nodeClient();
console.log('Node HttpClient injector: ready');
client.close();
