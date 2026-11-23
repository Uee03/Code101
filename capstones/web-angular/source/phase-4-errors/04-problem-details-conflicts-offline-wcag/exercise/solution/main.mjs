const headers = new Headers({ 'retry-after': '2' });
console.log(`Wait ${Number(headers.get('Retry-After'))} seconds; writes need another submit`);
