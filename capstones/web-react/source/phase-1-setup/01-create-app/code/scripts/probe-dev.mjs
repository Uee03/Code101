const response = await fetch('http://localhost:5173/');
if (response.status !== 200) throw new Error('Dev server failed');
console.log('dev: 200 on localhost:5173');
