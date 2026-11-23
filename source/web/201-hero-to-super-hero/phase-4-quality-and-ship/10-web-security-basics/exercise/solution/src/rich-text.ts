export function renderRichText(text: string): DocumentFragment {
  const fragment = document.createDocumentFragment();
  const parts = text.split("*");
  const lastIndex = parts.length - 1;
  const unclosed = parts.length % 2 === 0;

  parts.forEach((part, index) => {
    const odd = index % 2 === 1;
    const isUnclosedLast = unclosed && index === lastIndex;
    if (odd && !isUnclosedLast) {
      const strong = document.createElement("strong");
      strong.textContent = part;
      fragment.append(strong);
    } else {
      const prefix = odd && isUnclosedLast ? "*" : "";
      fragment.append(document.createTextNode(prefix + part));
    }
  });
  return fragment;
}
