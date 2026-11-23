import type { Comment } from "./comments";

// DEMONSTRATION ONLY. Never ship code like this: it inserts user-controlled text as HTML.
export function renderCommentUnsafe(comment: Comment): HTMLLIElement {
  const item = document.createElement("li");
  item.innerHTML = `<strong>${comment.name}</strong>: ${comment.message}`;
  return item;
}
