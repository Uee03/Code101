const root = document.documentElement;
const saved = localStorage.getItem('theme');
if (saved === 'light' || saved === 'dark') {
  root.dataset.theme = saved;
}

addEventListener('DOMContentLoaded', () => {
  const button = document.querySelector('#theme-toggle');
  if (!(button instanceof HTMLButtonElement)) {
    return;
  }
  const currentTheme = () =>
    root.dataset.theme ?? (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
  const sync = () => button.setAttribute('aria-pressed', String(currentTheme() === 'dark'));

  button.addEventListener('click', () => {
    const next = currentTheme() === 'dark' ? 'light' : 'dark';
    root.dataset.theme = next;
    localStorage.setItem('theme', next);
    sync();
  });
  sync();
});
