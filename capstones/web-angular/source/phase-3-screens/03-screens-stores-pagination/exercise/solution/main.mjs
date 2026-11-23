const page = { nextCursor: 'opaque_cursor' };
const query = new URLSearchParams({ limit: '25', cursor: page.nextCursor });
console.log(query.toString());
