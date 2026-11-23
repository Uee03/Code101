function message(count) {
  return "Clicks: " + count;
}
console.log(message(0));
if (typeof document !== "undefined") {
  const button = document.querySelector("#greet");
  const status = document.querySelector("#status");
  let clicks = 0;
  button.addEventListener("click", function () {
    clicks = clicks + 1;
    status.textContent = message(clicks);
  });
}
