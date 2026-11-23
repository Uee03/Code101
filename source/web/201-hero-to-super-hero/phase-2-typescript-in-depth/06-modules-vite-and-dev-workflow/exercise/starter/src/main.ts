import { requireElement } from "./dom";
import { notes } from "./notes";
import { renderNotes } from "./render";
import { latestVersion } from "./stats";

requireElement("#title", HTMLHeadingElement).textContent = import.meta.env.VITE_APP_TITLE ?? "Release notes";
requireElement("#mode", HTMLElement).textContent = import.meta.env.MODE;
renderNotes(requireElement("#notes", HTMLUListElement), notes);

const output = requireElement("#details-output", HTMLParagraphElement);
requireElement("#details-button", HTMLButtonElement).addEventListener("click", async () => {
  const { explain } = await import("./details");
  output.textContent = `${explain(notes.length)} Latest version: ${latestVersion(notes)}.`;
});
