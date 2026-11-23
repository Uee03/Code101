import { ApiClient, endpoint, type FetchLike } from "./client.js";
import { parseTask } from "./model.js";
import { parsePage } from "./page.js";

const fakeFetch: FetchLike = async () => ({
  ok: true,
  status: 200,
  json: async () => ({
    items: [
      { id: 1, title: "Write lesson", status: "todo" },
      { id: 2, title: "Review lesson", status: "done" },
    ],
    total: 5,
  }),
});

const client = new ApiClient("https://api.example.test", fakeFetch);
const listPage = endpoint("GET", "/tasks?page=1", parsePage(parseTask));

const result = await client.request(listPage);
if (result.ok) {
  console.log(`Showing ${result.value.items.length} of ${result.value.total} tasks`);
} else {
  console.log(`${result.error.kind} error - ${result.error.message}`);
}
