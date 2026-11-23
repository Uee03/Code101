const http = require("node:http");

const server = http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ message: "Hello from a multi-stage Node image", version: "__VERSION__" }) + "\n");
});

server.listen(8080, "0.0.0.0", () => console.log("Node app listening on 8080"));
