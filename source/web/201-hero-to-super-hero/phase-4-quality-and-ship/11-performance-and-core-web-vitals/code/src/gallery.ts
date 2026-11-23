const TILE_COUNT = 12;

export function renderGallery(list: HTMLElement): void {
  const items = Array.from({ length: TILE_COUNT }, (_, index) => {
    const item = document.createElement("li");
    const image = document.createElement("img");
    image.loading = "lazy";
    image.decoding = "async";
    image.width = 320;
    image.height = 200;
    image.alt = `Sample picture ${index + 1}`;
    image.src = `/images/tile.svg?tile=${index + 1}`;
    item.append(image);
    return item;
  });
  list.replaceChildren(...items);
}
