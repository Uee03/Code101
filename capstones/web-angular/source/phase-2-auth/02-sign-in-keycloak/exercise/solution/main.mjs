const candidate = '//example.invalid';
const safe = candidate.startsWith('/') && !candidate.startsWith('//') && !/[\\\r\n]/.test(candidate) ? candidate : '/';
console.log(`Return route: ${safe}`);
