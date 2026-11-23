const TILE_COUNT = 12;

// TODO 1: this version makes the page jump while images load, and fetches all 12 at once. Fix it:
//   - give every image width and height (320 and 200)
//   - load images lazily (loading = "lazy") and decode them off the main thread (decoding = "async")
// Set loading before src: the browser reads it when the source is set.
export function renderGallery(list: HTMLElement): void {
  const items = Array.from({ length: TILE_COUNT }, (_, index) => {
    const item = document.createElement("li");
    const image = document.createElement("img");
    image.alt = `Sample picture ${index + 1}`;
    image.src = `/images/tile.svg?tile=${index + 1}`;
    item.append(image);
    return item;
  });
  list.replaceChildren(...items);
}
