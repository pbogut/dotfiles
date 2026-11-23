// OpenCode alone draws hard line breaks inside a chat column beside a sidebar.
// Keep all guesses about that UI here; links.js only knows terminal soft wraps.
import { trimUrl, visibleLinks } from "./links.js";
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

export function openCodeLinks(text, cols, top, rows, files = false) {
  let links = visibleLinks(text, cols, top, rows, files);
  const lines = text.split("\n");
  // The prompt's lower border measures the chat, with or without a sidebar.
  // If this isn't a screen of painted rows, we can't use its newline indices
  // as screen positions. Keep the standard hints in that case.
  const screen = lines.slice(top, top + rows);
  const ruler = screen.findLastIndex((s) => /^ *╹▀{8,}(?:\s|$)/u.test(s));
  if (ruler < 0 || lines.slice(0, top + ruler + 1).some((s) => width(s) > cols)) return links;
  const edge = screen[ruler].match(/^ *╹▀+/u)[0].length;
  const chat = screen.slice(0, ruler).map((s) => chatColumn(s, edge));

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
    links = links.filter((l) => !l.path || l.row < row || l.row > at ||
      l.col !== (l.row === row ? startCol : marginCol));
    // If the first fragment already opens, leave its original hint alone. The
    // first continuation gets the full URL, including any further wrapped rows.
    links.push({
      row: short ? row + 1 : row,
      col: short ? marginCol : startCol,
      url: trimUrl(raw),
    });
  }
  return links.sort((a, b) => a.row - b.row || a.col - b.col);
}
