import { ApiClient, endpoint, type FetchLike, type FetchResponse, type Result } from "./client.js";
import { firstOr, getProp, parseArray } from "./generics.js";
import { parseTask } from "./model.js";

function jsonResponse(status: number, body: unknown): FetchResponse {
  return { ok: status >= 200 && status < 300, status, json: async () => body };
}

const fakeFetch: FetchLike = async (url) => {
  if (url.endsWith("/tasks")) {
    return jsonResponse(200, [
      { id: 1, title: "Write lesson", status: "todo" },
      { id: 2, title: "Review lesson", status: "done" },
    ]);
  }
  if (url.endsWith("/tasks/1")) {
    return jsonResponse(200, { id: 1, title: "Write lesson", status: "todo" });
  }
  if (url.endsWith("/tasks/2")) {
    return jsonResponse(200, { id: 2, title: "Broken", status: "archived" });
  }
  if (url.endsWith("/offline")) {
    throw new Error("socket closed");
  }
  return jsonResponse(404, { message: "not found" });
};

function show<T>(label: string, result: Result<T>, format: (value: T) => string): void {
  if (result.ok) {
    console.log(`${label}: ${format(result.value)}`);
  } else {
    console.log(`${label}: ${result.error.kind} error - ${result.error.message}`);
  }
}

console.log(firstOr([], "none"));
console.log(firstOr([3, 4], 0));
console.log(getProp({ id: 7, title: "Ship it" }, "title"));

const client = new ApiClient("https://api.example.test", fakeFetch);
const listTasks = endpoint("GET", "/tasks", parseArray(parseTask));
const getTask = (id: number) => endpoint("GET", `/tasks/${id}`, parseTask);
const offline = endpoint("GET", "/offline", parseTask);

show("list", await client.request(listTasks), (tasks) => tasks.map((task) => task.title).join(", "));
show("task 1", await client.request(getTask(1)), (task) => `${task.title} [${task.status}]`);
show("task 2", await client.request(getTask(2)), (task) => task.title);
show("task 99", await client.request(getTask(99)), (task) => task.title);
show("offline", await client.request(offline), (task) => task.title);
