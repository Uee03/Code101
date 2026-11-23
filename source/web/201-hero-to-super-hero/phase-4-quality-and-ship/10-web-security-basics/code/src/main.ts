import { cleanComment, type Comment } from "./comments";
import { requireElement } from "./dom";
import { renderComment } from "./safe-dom";
import { renderCommentUnsafe } from "./unsafe-demo";

const ATTACK_NAME = "<b>Mallory</b>";
const ATTACK_MESSAGE = `<img src="x" onerror="alert('XSS: this script ran')">`;
const ATTACK_WEBSITE = "javascript:alert(1)";
const CORS_BASE = "http://127.0.0.1:4000";

const form = requireElement("#comment-form", HTMLFormElement);
const nameInput = requireElement("#name", HTMLInputElement);
const messageInput = requireElement("#message", HTMLTextAreaElement);
const websiteInput = requireElement("#website", HTMLInputElement);
const safeList = requireElement("#safe-list", HTMLUListElement);
const unsafeList = requireElement("#unsafe-list", HTMLUListElement);
const corsButton = requireElement("#cors-button", HTMLButtonElement);
const corsResult = requireElement("#cors-result", HTMLUListElement);

function addComment(comment: Comment): void {
  safeList.append(renderComment(comment));
  unsafeList.append(renderCommentUnsafe(comment));
}

addComment({ name: "Ada", message: "Safe rendering shows *text* as text.", website: "https://developer.mozilla.org/" });

form.addEventListener("submit", (event) => {
  event.preventDefault();
  const comment = cleanComment(nameInput.value, messageInput.value, websiteInput.value);
  if (comment === null) {
    return;
  }
  addComment(comment);
  form.reset();
  nameInput.focus();
});

requireElement("#attack", HTMLButtonElement).addEventListener("click", () => {
  nameInput.value = ATTACK_NAME;
  messageInput.value = ATTACK_MESSAGE;
  websiteInput.value = ATTACK_WEBSITE;
});

async function probe(path: string, init?: RequestInit): Promise<string> {
  try {
    const response = await fetch(`${CORS_BASE}${path}`, init);
    const data: unknown = await response.json();
    return `${path}: ${JSON.stringify(data)}`;
  } catch (error) {
    return `${path}: blocked (${error instanceof Error ? error.name : "error"})`;
  }
}

corsButton.addEventListener("click", async () => {
  const lines = [
    await probe("/allowed"),
    await probe("/blocked"),
    await probe("/preflight", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ hello: "world" }),
    }),
  ];
  corsResult.replaceChildren(
    ...lines.map((line) => {
      const item = document.createElement("li");
      item.textContent = line;
      return item;
    }),
  );
});
