// TODO 1: support *bold*. Split the text on "*"; every odd-numbered piece becomes a <strong>
// element whose textContent is the piece. Everything else stays a text node.
// Never use innerHTML. If the stars are unbalanced, the last piece (with its star) stays plain text.
export function renderRichText(text: string): DocumentFragment {
  const fragment = document.createDocumentFragment();
  fragment.append(document.createTextNode(text));
  return fragment;
}
