import type { ReleaseNote } from "./notes";

export function renderNotes(list: HTMLElement, items: readonly ReleaseNote[]): void {
  const rows = items.map((note) => {
    const item = document.createElement("li");
    const heading = document.createElement("strong");
    heading.textContent = `${note.version} (${note.date})`;
    const summary = document.createElement("span");
    summary.textContent = ` - ${note.summary}`;
    item.append(heading, summary);
    return item;
  });
  list.replaceChildren(...rows);
}
