import { requireElement } from "./dom";
import { renderGallery } from "./gallery";
import { observeVitals } from "./vitals";

observeVitals({
  lcp: requireElement("#lcp", HTMLElement),
  cls: requireElement("#cls", HTMLElement),
  inp: requireElement("#inp", HTMLElement),
});
renderGallery(requireElement("#gallery", HTMLUListElement));

const workStatus = requireElement("#work-status", HTMLParagraphElement);

function blockFor(ms: number): void {
  const end = performance.now() + ms;
  while (performance.now() < end) {
    // Busy wait: the main thread cannot respond to anything else meanwhile.
  }
}

function nextTask(): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, 0));
}

requireElement("#slow", HTMLButtonElement).addEventListener("click", () => {
  blockFor(300);
  workStatus.textContent = "Slow click finished: the page was frozen for 300 ms.";
});

requireElement("#fast", HTMLButtonElement).addEventListener("click", async () => {
  workStatus.textContent = "Fast click: working in 30 ms slices...";
  for (let done = 0; done < 300; done += 30) {
    blockFor(30);
    await nextTask();
  }
  workStatus.textContent = "Fast click finished: the same 300 ms of work, in slices.";
});

function insertBanner(slotSelector: string): void {
  const slot = requireElement(slotSelector, HTMLDivElement);
  const banner = document.createElement("p");
  banner.className = "banner";
  banner.textContent = "A late banner, like an advert or a cookie notice.";
  slot.replaceChildren(banner);
}

requireElement("#banner-a", HTMLButtonElement).addEventListener("click", () => {
  setTimeout(() => insertBanner("#slot-a"), 1000);
});

requireElement("#banner-b", HTMLButtonElement).addEventListener("click", () => {
  setTimeout(() => insertBanner("#slot-b"), 1000);
});

const report = requireElement("#report", HTMLPreElement);
requireElement("#report-button", HTMLButtonElement).addEventListener("click", async () => {
  const { buildReport } = await import("./report");
  report.textContent = buildReport(12);
});
