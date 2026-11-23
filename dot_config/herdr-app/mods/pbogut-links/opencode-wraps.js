// OpenCode alone draws hard line breaks inside a chat column beside a sidebar.
// Keep all guesses about that UI here; links.js only knows terminal soft wraps.
import { trimUrl, visibleLinks } from "./links.js";
import { wrappedFiles } from "./file-wraps.js";
import { cellWidth, glyphs } from "./words.js";

const width = (s) => (s.match(glyphs) ?? []).reduce((n, g) => n + cellWidth(g), 0);
const startAtEnd = /\b(https?(?::(?:\/(?:\/[^\s<>"'`]*)?)?)?)$/i;
const firstToken = /^[\p{L}\p{N}._~:/?#@!$&()*+,;=%[\]-]+/u;
const hasHost = /^https?:\/\/(?:[\p{L}\p{N}-]+|\[[\da-f:]+\])/iu;

function chatColumn(line, edge) {
  let col = 0, end = 0;
  for (const glyph of line.match(glyphs) ?? []) {
    col += cellWidth(glyph);
    if (col > edge) break;
    end += glyph.length;
  }
  return line.slice(0, end).trimEnd();
}

// A table can be partly offscreen. Two matching vertical borders on
// consecutive rows suffice; a horizontal divider starts a new table cell.
function tableFiles(lines) {
  const latest = new Map(), cells = [];
  for (const [row, line] of lines.entries()) {
    if (!/^ *(?:┃ *)?│/u.test(line)) continue;
    const parts = line.split("│");
    let col = width(parts[0]) + 1;
    for (const text of parts.slice(1, -1)) {
      const span = width(text), key = `${col}:${span}`;
      let cell = latest.get(key);
      if (!cell || cell.row + cell.lines.length !== row) {
        cell = { row, col, span, lines: [] };
        latest.set(key, cell);
        cells.push(cell);
      }
      cell.lines.push(text.trimEnd());
      col += span + 1;
    }
  }
  return cells.filter((c) => c.lines.length > 1)
    .flatMap((c) => wrappedFiles(c.lines, c.span, new Set(), c));
}

export function openCodeLinks(text, cols, top, rows, files = false) {
  let links = visibleLinks(text, cols, top, rows, files);
  const lines = text.split("\n");
  // The prompt's lower border measures the chat, with or without a sidebar.
  // If this isn't a screen of painted rows, we can't use its newline indices
  // as screen positions. Keep the standard hints in that case.
  const screen = lines.slice(top, top + rows);
  const ruler = screen.findLastIndex((s) => /^ *╹▀{8,}(?:\s|$)/u.test(s));
  const end = ruler < 0 ? screen.length : ruler + 1;
  if (lines.slice(0, top + end).some((s) => width(s) > cols)) return links;
  if (ruler < 0) return files ? links.concat(tableFiles(screen)) : links;
  const edge = screen[ruler].match(/^ *╹▀+/u)[0].length;
  const chat = screen.slice(0, ruler).map((s) => chatColumn(s, edge));
  const urlParts = new Set();

  for (let row = 0; row + 1 < chat.length; row++) {
    const start = startAtEnd.exec(chat[row]);
    if (!start) continue;
    // Match the chat's indentation, including OpenCode's user-message rail.
    const margin = chat[row].match(/^ *(?:┃ *)?/u)[0];
    let raw = start[0], at = row;
    const short = hasHost.test(raw);
    while (at + 1 < chat.length) {
      const next = chat[at + 1];
      if (next.match(/^ *(?:┃ *)?/u)[0] !== margin) break;
      const tail = next.slice(margin.length);
      const token = firstToken.exec(tail)?.[0];
      if (!token || /^https?:/i.test(tail)) break;
      // An incomplete scheme is strong evidence. For an ambiguous wrap,
      // allow the few spare cells OpenCode leaves at the edge, or a longer
      // token that couldn't fit in the remaining space before the gutter.
      const room = edge - width(chat[at]);
      if (hasHost.test(raw) && room > 5 && width(token) + 2 <= room) break;
      const joined = raw + token;
      if (!hasHost.test(joined) && !/^https?:\/{0,2}$/i.test(joined)) break;
      raw = joined;
      at++;
      if (tail !== token || trimUrl(raw) !== raw) break;
    }
    if (at === row || !hasHost.test(raw)) continue;
    const startCol = width(chat[row].slice(0, start.index)), marginCol = width(margin);
    for (let r = row; r <= at; r++) urlParts.add(`${r}:${r === row ? startCol : marginCol}`);
    // If the first fragment already opens, leave its original hint alone. The
    // first continuation gets the full URL, including any further wrapped rows.
    links.push({
      row: short ? row + 1 : row,
      col: short ? marginCol : startCol,
      url: trimUrl(raw),
    });
  }
  if (files) {
    links = links.filter((l) => !l.path || !urlParts.has(`${l.row}:${l.col}`));
    links.push(...wrappedFiles(chat, edge, urlParts, { chat: true }));
    links.push(...tableFiles(chat));
  }
  return links.sort((a, b) => a.row - b.row || a.col - b.col);
}
