import { authSmoke } from './smoke-auth';
authSmoke().catch(error => { console.error(error.message); process.exitCode = 1; });
