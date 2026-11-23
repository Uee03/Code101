import { getJson } from "./api";
import { requireElement } from "./dom";
import { parseTasks, type Task } from "./model";
import { fetcherFor, isScenario, type Scenario } from "./scenarios";

type LoadState =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "success"; tasks: Task[] }
  | { status: "error"; message: string };

const scenarioSelect = requireElement("#scenario", HTMLSelectElement);
const loadButton = requireElement("#load", HTMLButtonElement);
const cancelButton = requireElement("#cancel", HTMLButtonElement);
const retryButton = requireElement("#retry", HTMLButtonElement);
const statusLine = requireElement("#status", HTMLParagraphElement);
const errorPanel = requireElement("#error", HTMLDivElement);
const errorText = requireElement("#error-text", HTMLParagraphElement);
const list = requireElement("#tasks", HTMLUListElement);

function taskItem(task: Task): HTMLLIElement {
  const item = document.createElement("li");
  item.textContent = `${task.title} (${task.status})`;
  return item;
}

function render(state: LoadState): void {
  cancelButton.hidden = state.status !== "loading";
  errorPanel.hidden = state.status !== "error";
  list.replaceChildren();

  switch (state.status) {
    case "idle":
      statusLine.textContent = "Nothing loaded yet.";
      break;
    case "loading":
      statusLine.textContent = "Loading tasks...";
      break;
    case "success":
      statusLine.textContent = `Loaded ${state.tasks.length} tasks.`;
      list.replaceChildren(...state.tasks.map(taskItem));
      break;
    case "error":
      statusLine.textContent = "";
      errorText.textContent = state.message;
      break;
  }
}

let current: AbortController | null = null;

async function load(): Promise<void> {
  current?.abort();
  const controller = new AbortController();
  current = controller;
  render({ status: "loading" });

  const chosen = scenarioSelect.value;
  const scenario: Scenario = isScenario(chosen) ? chosen : "normal";
  const result = await getJson("/api/tasks.json", parseTasks, {
    fetcher: fetcherFor(scenario),
    signal: controller.signal,
    timeoutMs: 8000,
  });

  if (current !== controller) {
    return;
  }
  current = null;
  if (result.ok) {
    render({ status: "success", tasks: result.value });
  } else {
    render({ status: "error", message: result.error.message });
  }
}

loadButton.addEventListener("click", () => void load());
retryButton.addEventListener("click", () => void load());
cancelButton.addEventListener("click", () => current?.abort());
render({ status: "idle" });
