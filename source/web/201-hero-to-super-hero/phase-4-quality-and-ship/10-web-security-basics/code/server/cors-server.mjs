import { createServer } from "node:http";

const ORIGIN = "http://localhost:5173";

function sendJson(response, status, body, headers = {}) {
  response.writeHead(status, { "Content-Type": "application/json", ...headers });
  response.end(JSON.stringify(body));
}

const server = createServer((request, response) => {
  const url = new URL(request.url ?? "/", "http://127.0.0.1:4000");
  const allow = { "Access-Control-Allow-Origin": ORIGIN };

  if (url.pathname === "/allowed") {
    sendJson(response, 200, { message: "CORS allowed" }, allow);
    return;
  }
  if (url.pathname === "/blocked") {
    sendJson(response, 200, { message: "the browser hides this from the page" });
    return;
  }
  if (url.pathname === "/preflight" && request.method === "OPTIONS") {
    response.writeHead(204, {
      ...allow,
      "Access-Control-Allow-Methods": "POST",
      "Access-Control-Allow-Headers": "Content-Type",
      "Access-Control-Max-Age": "600",
    });
    response.end();
    return;
  }
  if (url.pathname === "/preflight" && request.method === "POST") {
    sendJson(response, 200, { ok: true }, allow);
    return;
  }
  sendJson(response, 404, { message: "not found" });
});

server.listen(4000, "127.0.0.1", () => {
  console.log("CORS demo server listening on http://127.0.0.1:4000");
});
