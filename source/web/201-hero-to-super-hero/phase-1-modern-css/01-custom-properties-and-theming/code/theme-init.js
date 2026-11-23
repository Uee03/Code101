(function () {
  try {
    const saved = localStorage.getItem("theme");
    if (saved === "light" || saved === "dark") {
      document.documentElement.dataset.theme = saved;
    }
  } catch {
    // Storage can be blocked (private mode, strict settings): keep the system theme.
  }
})();
