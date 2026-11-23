const region = document.querySelector(".toast-region");
const motionState = document.querySelector("#motion-state");
const motionQuery = window.matchMedia("(prefers-reduced-motion: reduce)");

const MESSAGES = {
  info: "Draft saved.",
  warning: "Connection is slow; changes will sync later.",
};

function showToast(kind, trigger) {
  const message = MESSAGES[kind];
  if (!message) {
    return;
  }

  const toast = document.createElement("div");
  toast.className = `toast toast--${kind}`;

  const text = document.createElement("span");
  text.className = "toast__text";
  text.textContent = message;

  const close = document.createElement("button");
  close.className = "btn btn--ghost toast__close";
  close.type = "button";
  close.textContent = "Dismiss";
  close.addEventListener("click", () => {
    toast.remove();
    trigger.focus();
  });

  toast.append(text, close);
  region.append(toast);
}

for (const button of document.querySelectorAll("[data-toast]")) {
  button.addEventListener("click", () => showToast(button.dataset.toast, button));
}

function showMotionState() {
  motionState.textContent = motionQuery.matches ? "reduced" : "no preference";
}

motionQuery.addEventListener("change", showMotionState);
showMotionState();
