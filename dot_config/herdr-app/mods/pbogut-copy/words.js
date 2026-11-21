const glyphs =
  /(?:\p{Regional_Indicator}{2}|[^\p{Mark}\u200d])[\p{Mark}\p{Emoji_Modifier}\ufe0e\ufe0f]*(?:\u200d.[\p{Mark}\p{Emoji_Modifier}\ufe0e\ufe0f]*)*/gu;

function cellWidth(glyph) {
  const code = glyph.codePointAt(0);
  if (/\p{Emoji_Presentation}|\ufe0f/u.test(glyph)) return 2;
  return code >= 0x1100 &&
    (code <= 0x115f ||
      code === 0x2329 ||
      code === 0x232a ||
      (code >= 0x2e80 && code <= 0xa4cf && code !== 0x303f) ||
      (code >= 0xac00 && code <= 0xd7a3) ||
      (code >= 0xf900 && code <= 0xfaff) ||
      (code >= 0xfe10 && code <= 0xfe19) ||
      (code >= 0xfe30 && code <= 0xfe6f) ||
      (code >= 0xff00 && code <= 0xff60) ||
      (code >= 0xffe0 && code <= 0xffe6) ||
      (code >= 0x20000 && code <= 0x3fffd))
    ? 2
    : 1;
}

// Core joins soft-wrapped rows and trims unused rows at the bottom. Rebuild
// cell positions, keeping a word together across wraps but not hard newlines.
export function wordTarget(text, cols, rows, at, motion) {
  const words = [];
  const whitespaceOnly = ["W", "E", "B"].includes(motion);
  motion = motion.toLowerCase();
  let row = 0,
    lineEnd = 0;
  for (const line of text.split("\n")) {
    let col = 0,
      previous = 0,
      word;
    if (!line && row < rows) words.push({ start: row * cols, end: row * cols, empty: true });
    for (const glyph of line.match(glyphs) ?? []) {
      const width = cellWidth(glyph);
      if (col + width > cols) {
        row++;
        col = 0;
      }
      if (row >= rows) break;
      const kind = /^\s/u.test(glyph) ? 0 : whitespaceOnly || /^[\p{L}\p{N}_]/u.test(glyph) ? 1 : 2;
      const cell = row * cols + col;
      if (motion === "^" && row === at.row) {
        if (kind) return { row, col };
        lineEnd = col;
      }
      if (kind) {
        if (kind !== previous) {
          word = { start: cell, end: cell };
          words.push(word);
        } else word.end = cell;
      }
      previous = kind;
      col += width;
    }
    row++;
    if (row >= rows) break;
  }
  if (motion === "^") return { row: at.row, col: lineEnd };
  const cell = at.row * cols + at.col;
  let target;
  if (motion === "b") {
    target = words.findLast((word) => word.start < cell)?.start ?? words[0]?.start;
    target = Math.min(cell, target ?? cell);
  } else {
    target =
      motion === "w"
        ? words.find((word) => word.start > cell)?.start
        : words.find((word) => !word.empty && word.end > cell)?.end;
    target = Math.max(cell, target ?? words.at(-1)?.end ?? cell);
  }
  return { row: Math.floor(target / cols), col: target % cols };
}
