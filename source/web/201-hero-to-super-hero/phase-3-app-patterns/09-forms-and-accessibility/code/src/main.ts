import { readDraft, todayLocal } from "./draft";
import { requireElement } from "./dom";
import { messageFor, summaryTitle } from "./validation";

interface FieldRef {
  readonly name: string;
  readonly control: HTMLInputElement;
  readonly error: HTMLParagraphElement;
  readonly marksInvalid: boolean;
}

interface Problem {
  readonly field: FieldRef;
  readonly message: string;
}

const form = requireElement("#task-form", HTMLFormElement);
const summary = requireElement("#error-summary", HTMLElement);
const summaryHeading = requireElement("#error-summary-title", HTMLHeadingElement);
const errorList = requireElement("#error-list", HTMLUListElement);
const saved = requireElement("#saved", HTMLParagraphElement);
const titleInput = requireElement("#title", HTMLInputElement);
const dueInput = requireElement("#due", HTMLInputElement);

const fields: readonly FieldRef[] = [
  { name: "title", control: titleInput, error: requireElement("#title-error", HTMLParagraphElement), marksInvalid: true },
  { name: "due", control: dueInput, error: requireElement("#due-error", HTMLParagraphElement), marksInvalid: true },
  {
    name: "priority",
    control: requireElement("#priority-low", HTMLInputElement),
    error: requireElement("#priority-error", HTMLParagraphElement),
    marksInvalid: false,
  },
];

let submitted = false;
dueInput.min = todayLocal();

function showFieldError(field: FieldRef, message: string | null): void {
  field.error.hidden = message === null;
  field.error.textContent = message === null ? "" : `Error: ${message}`;
  if (field.marksInvalid) {
    if (message === null) {
      field.control.removeAttribute("aria-invalid");
    } else {
      field.control.setAttribute("aria-invalid", "true");
    }
  }
}

function showSummary(problems: readonly Problem[]): void {
  summary.hidden = problems.length === 0;
  summaryHeading.textContent = summaryTitle(problems.length);
  const items = problems.map(({ field, message }) => {
    const item = document.createElement("li");
    const link = document.createElement("a");
    link.href = `#${field.control.id}`;
    link.textContent = message;
    item.append(link);
    return item;
  });
  errorList.replaceChildren(...items);
}

function validate(): Problem[] {
  titleInput.setCustomValidity(titleInput.value.trim().length >= 3 ? "" : "Too short");
  const problems: Problem[] = [];
  for (const field of fields) {
    const message = messageFor(field.name, field.control.validity);
    showFieldError(field, message);
    if (message !== null) {
      problems.push({ field, message });
    }
  }
  return problems;
}

function clearErrors(): void {
  for (const field of fields) {
    showFieldError(field, null);
  }
  showSummary([]);
}

form.addEventListener("submit", (event) => {
  event.preventDefault();
  submitted = true;
  const problems = validate();
  showSummary(problems);
  if (problems.length > 0) {
    saved.textContent = "";
    summary.focus();
    return;
  }
  const draft = readDraft(form);
  if (draft === null) {
    return;
  }
  saved.textContent = `Saved "${draft.title}", due ${draft.due}, ${draft.priority} priority.`;
  form.reset();
  submitted = false;
  clearErrors();
  titleInput.focus();
});

form.addEventListener("input", () => {
  if (submitted) {
    showSummary(validate());
  }
});

form.addEventListener("change", () => {
  if (submitted) {
    showSummary(validate());
  }
});

errorList.addEventListener("click", (event) => {
  const target = event.target;
  if (!(target instanceof HTMLAnchorElement)) {
    return;
  }
  event.preventDefault();
  const control = document.getElementById(target.hash.slice(1));
  if (control instanceof HTMLElement) {
    control.focus();
  }
});
