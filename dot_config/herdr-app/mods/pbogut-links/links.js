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

const web = /\bhttps?:\/\/[^\s<>"'`\x00-\x1f]+/gi;
// Match a whole relative token between prose delimiters. Consume URLs first
// so even a path in a URL's query string cannot get a file hint.
const file = /(?<![^\s("'`[<{│┃|])([\p{L}\p{N}_.@+-][\p{L}\p{M}\p{N}_./@+-]*)(?::(\d+)(?:[-–]\d+)?|#L(\d+)(?:[-–]L\d+)?)?(?=[.,;:!?]*(?:[\s)"'`\]}>│┃|]|$))/iu;
const webOrFile = new RegExp(`${web.source}|${file.source}`, "giu");

function fileTarget(match) {
  const path = match[1].replace(/\.+$/, ""), digits = match[2] ?? match[3];
  const line = digits === undefined ? null : Number(digits);
  if (path && (line === null || (Number.isSafeInteger(line) && line > 0)))
    return { path, line };
}

export function parseFile(token) {
  const match = file.exec(token);
  return match?.index === 0 && fileTarget(match);
}

// hc returns logical lines. Count display cells, not UTF-16 offsets, when
// placing a label after a wide glyph or on a soft-wrapped row.
export function visibleLinks(text, cols, top, rows, files = false) {
  const found = [];
  let row = 0;
  for (const line of text.split("\n")) {
    if (row >= top + rows) break;
    const matches = line.matchAll(files ? webOrFile : web);
    let match = matches.next().value, col = 0, index = 0;
    for (const glyph of line.match(glyphs) ?? []) {
      const width = cellWidth(glyph);
      if (col + width > cols) { row++; col = 0; }
      if (match?.index === index) {
        if (row >= top && row < top + rows) {
          const pos = { row: row - top, col };
          if (match[1]) {
            const target = fileTarget(match);
            if (target) found.push({ ...pos, ...target });
          } else {
            const url = trimUrl(match[0]);
            if (/^https?:\/\/[^/?#]/i.test(url)) found.push({ ...pos, url });
          }
        }
        match = matches.next().value;
      }
      col += width;
      index += glyph.length;
    }
    row++;
  }
  return found;
}

export async function existingTargets(targets, exec, options) {
  const paths = [...new Set(targets.filter((t) => t.path).map((t) => t.path))];
  if (!paths.length) return targets;
  const result = await exec("sh", ["-c",
    'for p do if [ -f "$p" ]; then printf "%s\\n" "$p"; fi; done', "files", ...paths], options);
  const existing = new Set(result.code === 0 ? result.stdout.split("\n") : []);
  const valid = targets.filter((t) => t.url || existing.has(t.path));
  if (!valid.some((t) => t.wrap)) return valid;
  const cell = ({ row, col }) => `${row}:${col}`;
  const labels = new Map(valid.filter((t) => !t.wrap).map((t) => [cell(t), t]));
  // Try the longest existing join at the earliest start. If it doesn't
  // exist, the individual fragments keep their ordinary hints.
  const joined = valid.filter((t) => t.wrap).sort((a, b) =>
    a.row - b.row || a.col - b.col || b.wrap.length - a.wrap.length);
  const used = new Set();
  for (const { row, col, path, line, wrap } of joined) {
    const key = cell({ row, col }), short = labels.get(key);
    if (used.has(key) || short?.url) continue;
    const pos = short && short.path !== path ? wrap[0] : { row, col };
    used.add(key);
    for (const part of wrap) {
      used.add(cell(part));
      labels.delete(cell(part));
    }
    labels.set(cell(pos), { ...pos, path, line });
  }
  return [...labels.values()].sort((a, b) => a.row - b.row || a.col - b.col);
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
