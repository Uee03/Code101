import { reduceBoard } from "./board";
import { requireElement } from "./dom";
import { mountBoard } from "./mount";
import { createStore } from "./store";
import { loadBoard, saveBoard } from "./storage";

const store = createStore(reduceBoard, loadBoard());

const form = requireElement("#add-form", HTMLFormElement);
const titleInput = requireElement("#title", HTMLInputElement);
const titleError = requireElement("#title-error", HTMLParagraphElement);
const status = requireElement("#status", HTMLParagraphElement);

store.subscribe((state) => saveBoard(state));

mountBoard(requireElement("#board", HTMLDivElement), store, {
  announce: (message) => {
    status.textContent = message;
  },
  afterRemove: () => titleInput.focus(),
});

function showError(message: string): void {
  titleError.hidden = false;
  titleError.textContent = `Error: ${message}`;
  titleInput.setAttribute("aria-invalid", "true");
  titleInput.focus();
}

function clearError(): void {
  titleError.hidden = true;
  titleError.textContent = "";
  titleInput.removeAttribute("aria-invalid");
}

form.addEventListener("submit", (event) => {
  event.preventDefault();
  const title = titleInput.value.trim();
  if (title === "") {
    showError("enter a title for the task.");
    return;
  }
  const before = store.getState();
  store.dispatch({ type: "added", title });
  if (store.getState() === before) {
    showError("the title is too long (80 characters at most).");
    return;
  }
  clearError();
  status.textContent = `Added "${title}" to To do.`;
  form.reset();
  titleInput.focus();
});
