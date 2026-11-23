interface Todo {
  id: number;
  text: string;
  done: boolean;
}
function taskCount(todos: Todo[]): string {
  return todos.length + " tasks";
}
console.log(taskCount([]));
function start(): void {
  const form = document.querySelector("#todo-form");
  const input = document.querySelector("#task");
  const list = document.querySelector("#tasks");
  const status = document.querySelector("#status");
  if (!(form instanceof HTMLFormElement) ||
      !(input instanceof HTMLInputElement) || !list || !status) return;
  const key = "code101-web-todos-v1";
  let todos: Todo[] = [];
  let storageNotice = "";
  try {
    const saved: unknown = JSON.parse(localStorage.getItem(key) ?? "[]");
    if (Array.isArray(saved)) {
      todos = saved.filter((item): item is Todo =>
        typeof item === "object" && item !== null &&
        typeof item.id === "number" && typeof item.text === "string" &&
        typeof item.done === "boolean");
    }
  } catch {
    storageNotice = " Saved tasks unavailable; starting empty.";
  }
  function save(): void {
    try {
      localStorage.setItem(key, JSON.stringify(todos));
      storageNotice = "";
    } catch {
      storageNotice = " Storage unavailable; changes last only this visit.";
    }
  }
  const render = function (): void {
    list.replaceChildren();
    status.textContent = taskCount(todos) + storageNotice;
    for (const todo of todos) {
      const item = document.createElement("li");
      const label = document.createElement("span");
      label.textContent = todo.text;
      if (todo.done) label.className = "done";
      const toggle = document.createElement("button");
      toggle.type = "button";
      toggle.textContent = todo.done ? "Undo" : "Done";
      toggle.setAttribute("aria-label", "Mark " + todo.text + (todo.done ? " as not done (Undo)" : " as done (Done)"));
      toggle.addEventListener("click", function () {
        todo.done = !todo.done;
        save();
        render();
      });
      const remove = document.createElement("button");
      remove.type = "button";
      remove.textContent = "Remove";
      remove.setAttribute("aria-label", "Remove " + todo.text);
      remove.addEventListener("click", function () {
        todos = todos.filter(function (item) { return item.id !== todo.id; });
        save();
        render();
      });
      item.append(label, toggle, remove);
      list.append(item);
    }
  };
  form.addEventListener("submit", function (event) {
    event.preventDefault();
    const text = input.value.trim();
    if (text === "") return;
    todos.push({ id: Date.now(), text: text, done: false });
    input.value = "";
    save();
    render();
    input.focus();
  });
  const clear = document.querySelector("#clear");
  if (clear) {
    clear.addEventListener("click", function () {
      todos = [];
      save();
      render();
    });
  }
  render();
}
if (typeof document !== "undefined") {
  start();
}
