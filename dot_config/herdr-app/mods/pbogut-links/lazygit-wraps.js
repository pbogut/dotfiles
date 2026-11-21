// Lazygit paints adjacent panel borders as part of the terminal text. Locate
// each closed box in display cells, then only join rows inside that box.
import { trimUrl, visibleLinks } from "./links.js";
import { cellWidth, glyphs } from "./words.js";

function cells(line) {
  return (line.match(glyphs) ?? []).flatMap((g) => cellWidth(g) === 2 ? [g, ""] : [g]);
}

function* panels(screen) {
  for (const [top, header] of screen.entries()) {
    for (const [left, corner] of header.entries()) {
      const rounded = corner === "╭";
      if (!rounded && corner !== "┌") continue;
      const right = header.indexOf(rounded ? "╮" : "┐", left + 1);
      if (right < left + 2 || !header.slice(left + 1, right).includes("─")) continue;
      for (let y = top + 1; y < screen.length; y++) {
        const a = screen[y][left], b = screen[y][right];
        if (a === (rounded ? "╰" : "└") && b === (rounded ? "╯" : "┘")) {
          yield { left, right, top, bottom: y };
          break;
        }
        if (a !== "│" || (b !== "│" && b !== "▐")) break;
      }
    }
  }
}

const suffix = /\bhttps?(?::(?:\/(?:\/[^\s<>"'`]*)?)?)?$/i;
const hasHost = /^https?:\/\/(?:[\p{L}\p{N}-]+|\[[\da-f:]+\])/iu;
const token = /^[\p{L}\p{N}._~:/?#@!$&()*+,;=%[\]-]+/u;

function scanPanel(content, width) {
  const links = visibleLinks(content.join("\n"), width, 0, content.length);
  for (let row = 0; row + 1 < content.length; row++) {
    const start = suffix.exec(content[row]);
    if (!start) continue;
    let raw = start[0], at = row, continuation;
    while (at + 1 < content.length) {
      const next = content[at + 1].trimStart();
      const part = token.exec(next)?.[0];
      if (!part || /^[a-z][\w+.-]*:(?!\d)/iu.test(next)) break;
      // A path or query can break early. For plain words, only offer a
      // join if the word did not fit, or the previous row filled the panel.
      const room = width - cells(content[at]).length;
      if (hasHost.test(raw) && !/^[/#?&=%]/.test(part) && room > 2 && cells(part).length <= room) break;
      const joined = raw + part;
      if (!hasHost.test(joined) && !/^https?:\/{0,2}$/i.test(joined)) break;
      continuation ??= cells(content[at + 1]).length - cells(next).length;
      raw = joined;
      at++;
      if (part !== next || trimUrl(raw) !== raw) break;
    }
    if (at === row || !hasHost.test(raw)) continue;
    const short = hasHost.test(start[0]);
    links.push({
      row: short ? row + 1 : row,
      col: short ? continuation : cells(content[row].slice(0, start.index)).length,
      url: trimUrl(raw),
    });
  }
  return links;
}

export function lazygitLinks(text, cols, top, rows) {
  const ordinary = visibleLinks(text, cols, top, rows);
  const lines = text.split("\n").slice(0, top + rows).map(cells);
  if (lines.some((line) => line.length > cols)) return ordinary;
  const screen = lines.slice(top), boxes = [...panels(screen)];
  const links = ordinary.filter(({ row, col }) => !boxes.some((b) =>
    row > b.top && row < b.bottom && col > b.left && col < b.right));
  for (const { left, right, top: y, bottom } of boxes) {
    const content = screen.slice(y + 1, bottom).map((line) =>
      line.slice(left + 1, right).join("").trimEnd());
    for (const link of scanPanel(content, right - left - 1))
      links.push({ row: y + 1 + link.row, col: left + 1 + link.col, url: link.url });
  }
  return links.sort((a, b) => a.row - b.row || a.col - b.col);
}
