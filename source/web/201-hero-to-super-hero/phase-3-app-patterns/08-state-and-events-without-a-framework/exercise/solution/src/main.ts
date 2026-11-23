import { requireElement } from "./dom";
import { emit, on } from "./events";
import { subscribeTo } from "./select";
import { createStore } from "./store";
import { initialState, openCount, reduce, visibleTasks, type Filter, type State } from "./tasks";
import { appendActivity, renderFilters, renderTasks } from "./view";

const store = createStore(reduce, initialState);

const form = requireElement("#add-form", HTMLFormElement);
const titleInput = requireElement("#title", HTMLInputElement);
const list = requireElement("#tasks", HTMLUListElement);
const summary = requireElement("#summary", HTMLParagraphElement);
const filters = requireElement("#filters", HTMLDivElement);
const log = requireElement("#activity", HTMLUListElement);

function isFilter(value: string | undefined): value is Filter {
  return value === "all" || value === "open" || value === "done";
}

function paintList(state: State): void {
  renderTasks(list, visibleTasks(state));
  renderFilters(filters, state.filter);
}

store.subscribe(paintList);
paintList(store.getState());
subscribeTo(store, openCount, (count) => {
  summary.textContent = `${count} open`;
});

form.addEventListener("submit", (event) => {
  event.preventDefault();
  const title = titleInput.value.trim();
  if (title === "") {
    titleInput.focus();
    return;
  }
  store.dispatch({ type: "added", title });
  emit(document, "task:added", { title });
  form.reset();
  titleInput.focus();
});

list.addEventListener("change", (event) => {
  const target = event.target;
  if (target instanceof HTMLInputElement && target.dataset.action === "toggle") {
    store.dispatch({ type: "toggled", id: Number(target.dataset.id) });
  }
});

list.addEventListener("click", (event) => {
  const target = event.target;
  if (!(target instanceof Element)) {
    return;
  }
  const button = target.closest<HTMLButtonElement>("button[data-action='remove']");
  if (button === null) {
    return;
  }
  const id = Number(button.dataset.id);
  store.dispatch({ type: "removed", id });
  emit(document, "task:removed", { id });
  titleInput.focus();
});

filters.addEventListener("click", (event) => {
  const target = event.target;
  if (!(target instanceof HTMLButtonElement)) {
    return;
  }
  const wanted = target.dataset.filter;
  if (isFilter(wanted)) {
    store.dispatch({ type: "filter-changed", filter: wanted });
  }
});

on(document, "task:added", ({ title }) => appendActivity(log, `Added "${title}"`));
on(document, "task:removed", ({ id }) => appendActivity(log, `Removed task #${id}`));
