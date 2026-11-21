import assert from "node:assert/strict";
import { test } from "node:test";
import { openCodeLinks } from "../../../dot_config/herdr-app/mods/pbogut-links/opencode-wraps.js";
import { visibleLinks } from "../../../dot_config/herdr-app/mods/pbogut-links/links.js";

function screen(edge, chat, sidebar = []) {
  const border = "  ╹" + "▀".repeat(edge - 3);
  return [...chat.map((line, i) => line.padEnd(edge + 4) + (sidebar[i] ?? "")), border].join("\n");
}
const scan = (text) => openCodeLinks(text, 150, 0, 40);

test("the sidebar snapshot's bare scheme opens the hostname from the chat column", () => {
  const text = screen(99, [
    "     open. Esc cancels. The shortcut is installed, and the changes are open for review (http://",
    "     plannotator.localhost:46231).",
  ], ["▼ MCP", "• browser-personal"]);
  assert.deepEqual(scan(text), [{row: 0, col: 88, url: "http://plannotator.localhost:46231"}]);
  assert.deepEqual(visibleLinks(text, 150, 0, 40), []);
  assert.deepEqual(scan(text.split("\n").slice(0, -1).join("\n")), []);
});

test("split schemes make one target on the original h, even away from the edge", () => {
  for (const [start, end] of [["http", "://host.test"], ["https:", "//host.test"], ["https:/", "/host.test"]]) {
    assert.deepEqual(scan(screen(62, [`     界 ${start}`, `     ${end}`])), [
      {row: 0, col: 8, url: `${start}${end}`},
    ]);
  }
});

test("ambiguous wrap has two distinct targets; a third row extends the second", () => {
  const text = screen(33, [
    "  ┃  Read https://example.com/ab",
    "  ┃  cd?token=1234567890123456789",
    "  ┃  &more=yes).",
  ]);
  assert.deepEqual(scan(text), [
    {row: 0, col: 10, url: "https://example.com/ab"},
    {row: 1, col: 5, url: "https://example.com/abcd?token=1234567890123456789&more=yes"},
  ]);
});

test("avoid joins across chat blocks, sidebar entries or independent links", () => {
  for (const text of [
    screen(40, ["     https://a.test", "     next paragraph"]),
    screen(40, ["     (http://", "  ┃  unrelated.test"]),
    screen(40, ["     (http://", ""], ["", "example.com"]),
    screen(40, ["     https://example.com/123456789", "     https://other.test"]),
  ]) assert.deepEqual(scan(text), visibleLinks(text, 150, 0, 40));
});
