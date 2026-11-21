import { cellWidth, glyphs } from "./words.js";

export function trimUrl(url) {
  const pairs = { ")": "(", "]": "[", "}": "{" };
  for (;;) {
    url = url.replace(/[.,;:!?]+$/, "");
    const close = url.at(-1), open = pairs[close];
    if (!open || url.split(close).length <= url.split(open).length) return url;
    url = url.slice(0, -1);
  }
}

// hc returns logical lines. Count display cells, not UTF-16 offsets, when
// placing a label after a wide glyph or on a soft-wrapped row.
export function visibleLinks(text, cols, top, rows) {
  const found = [];
  let row = 0;
  for (const line of text.split("\n")) {
    if (row >= top + rows) break;
    const matches = line.matchAll(/\bhttps?:\/\/[^\s<>"'`\x00-\x1f]+/gi);
    let match = matches.next().value, col = 0, index = 0;
    for (const glyph of line.match(glyphs) ?? []) {
      const width = cellWidth(glyph);
      if (col + width > cols) { row++; col = 0; }
      if (match?.index === index) {
        const url = trimUrl(match[0]);
        if (row >= top && row < top + rows && /^https?:\/\/[^/?#]/i.test(url))
          found.push({ row: row - top, col, url });
        match = matches.next().value;
      }
      col += width;
      index += glyph.length;
    }
    row++;
  }
  return found;
}

// Herdr fits whole cells and centers the unused height. Simply dividing the
// width by cols would distribute the unused right margin across every label.
// The configured monitors use 1x or 2x scale (integer or half-pixel cells).
export function grid(box, cols, rows, zoom, fontSize) {
  const step = (length, count, nominal) => {
    const hi = Math.floor(2 * length / count) / 2;
    const lo = (Math.floor(2 * length / (count + 1)) + 1) / 2;
    return Math.max(lo, Math.min(hi, Math.round(2 * nominal) / 2));
  };
  const w = step(box.width, cols, fontSize * zoom * 0.6);
  const h = step(box.height, rows, fontSize * zoom * 1.32);
  return {
    left: box.left / zoom, top: Math.floor(Math.max(0, box.height - rows * h) / 2) / zoom,
    w: w / zoom, h: h / zoom,
  };
}
