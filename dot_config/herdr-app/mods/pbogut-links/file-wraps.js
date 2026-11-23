import { parseFile } from "./links.js";
import { cellWidth, glyphs } from "./words.js";

const width = (s) => (s.match(glyphs) ?? []).reduce((n, g) => n + cellWidth(g), 0);
const endToken = /(?<![^\s("'`[<{│┃|])([\p{L}\p{N}_.@+-][\p{L}\p{M}\p{N}_./@+:–-]*)$/u;
const firstToken = /^[\p{L}\p{M}\p{N}_./@+:–-]+(?=[,;!?]*(?:[\s)"'`\]}>]|$))/u;
const lineSuffix = /:\d*(?:[-–]\d*)?$/;

// Each row is already clipped to one panel or the chat column. Keep partial
// joins too: only the filesystem can tell which row actually ends the path.
export function wrappedFiles(lines, edge, urlParts, { chat = false, row: y = 0, col: x = 0 } = {}) {
  const found = [];
  const margin = chat ? /^ *(?:┃ *)?/u : /^ */u;
  const margins = lines.map((s) => s.match(margin)[0]);
  const rooms = lines.map((s) => edge - width(s));
  for (let row = 0; row + 1 < lines.length; row++) {
    const start = endToken.exec(lines[row]);
    if (!start) continue;
    const before = lines[row].slice(0, start.index), col = width(before);
    if (urlParts.has(`${row}:${col}`) || /\bhttps?:\/\/[^\s<>"'`]*$/i.test(before)) continue;
    let raw = start[0];
    const wrap = [];
    for (let at = row + 1; at < lines.length; at++) {
      if (chat && margins[at] !== margins[row]) break;
      const indent = width(margins[at]), tail = lines[at].slice(margins[at].length);
      const part = firstToken.exec(tail)?.[0];
      if (!part || urlParts.has(`${at}:${indent}`) || /^[a-z][\w+.-]*:\/\//i.test(tail)) break;
      // A slash boundary or split line suffix can wrap early. Otherwise
      // the continuation must plausibly have run out of room.
      if (!raw.endsWith("/") && !/^[/:–-]/.test(part) && !lineSuffix.test(raw) &&
          rooms[at - 1] > 4 && width(part) + 2 <= rooms[at - 1]) break;
      raw += part;
      wrap.push({ row: y + at, col: x + indent });
      const target = parseFile(raw);
      if (target) found.push({ row: y + row, col: x + col, ...target, wrap: [...wrap] });
      if (tail !== part || (!target && !lineSuffix.test(raw))) break;
    }
  }
  return found;
}
