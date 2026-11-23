import type { Comment } from "./comments";
import { renderRichText } from "./rich-text";

export function safeUrl(value: string): string | null {
  try {
    const url = new URL(value);
    return url.protocol === "https:" || url.protocol === "http:" ? url.href : null;
  } catch {
    return null;
  }
}

export function renderComment(comment: Comment): HTMLLIElement {
  const item = document.createElement("li");

  const name = document.createElement("strong");
  name.textContent = comment.name;

  const message = document.createElement("span");
  message.append(": ", renderRichText(comment.message));
  item.append(name, message);

  const href = safeUrl(comment.website);
  if (href !== null) {
    const link = document.createElement("a");
    link.href = href;
    link.textContent = "website";
    link.rel = "noopener noreferrer nofollow ugc";
    item.append(" ", link);
  }
  return item;
}
