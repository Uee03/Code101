export function renderRichText(text: string): DocumentFragment {
  const fragment = document.createDocumentFragment();
  fragment.append(document.createTextNode(text));
  return fragment;
}
