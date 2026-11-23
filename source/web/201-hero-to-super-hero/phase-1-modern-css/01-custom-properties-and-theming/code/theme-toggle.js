const root = document.documentElement;
const toggle = document.querySelector("#theme-toggle");
const darkQuery = window.matchMedia("(prefers-color-scheme: dark)");

function currentTheme() {
  const chosen = root.dataset.theme;
  if (chosen === "light" || chosen === "dark") {
    return chosen;
  }
  return darkQuery.matches ? "dark" : "light";
}

function showTheme() {
  toggle.setAttribute("aria-pressed", String(currentTheme() === "dark"));
}

function saveTheme(theme) {
  try {
    localStorage.setItem("theme", theme);
  } catch {
    // Not saved: the choice still applies until the page closes.
  }
}

toggle.addEventListener("click", () => {
  const next = currentTheme() === "dark" ? "light" : "dark";
  root.dataset.theme = next;
  saveTheme(next);
  showTheme();
});

darkQuery.addEventListener("change", showTheme);
showTheme();
