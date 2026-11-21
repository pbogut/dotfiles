import assert from "node:assert/strict";
import { test } from "node:test";
import { lazygitLinks } from "../../../dot_config/herdr-app/mods/pbogut-links/lazygit-wraps.js";

const box = (width, title, body) => [
  `╭${("─" + title).padEnd(width, "─")}╮`,
  ...body.map((s) => `│${s.padEnd(width)}│`),
  `╰${"─".repeat(width)}╯`,
];
const scan = (lines) => lazygitLinks(lines.join("\n"), 150, 0, lines.length);

test("a GitLab push URL wraps early inside a panel with a scrollbar", () => {
  const short = "https://gitlab.test/team/project/-";
  const path = "/merge_requests/new?merge_request%5Bsource_branch%5D=feature";
  const lines = box(85, "arbitrary panel", ["remote:   " + short, path, "remote:"]);
  lines[1] = lines[1].slice(0, -1) + "▐";
  assert.deepEqual(scan(lines), [
    {row: 1, col: 11, url: short}, {row: 2, col: 1, url: short + path},
  ]);
});

test("side-by-side boxes keep their own fragments even against the borders", () => {
  const left = box(18, "Files", ["https://a.test/abc", "def", "https://x.test"]);
  const right = box(27, "Diff", ["see http", "://localhost:1234/path", "/tail"]);
  assert.deepEqual(scan(left.map((s, i) => s + right[i])), [
    {row: 1, col: 1, url: "https://a.test/abc"},
    {row: 1, col: 25, url: "http://localhost:1234/path/tail"},
    {row: 2, col: 1, url: "https://a.test/abcdef"},
    {row: 3, col: 1, url: "https://x.test"},
  ]);
});

test("stacked boxes and a footer don't join; a wide glyph counts as two cells", () => {
  const upper = box(30, "Log", ["界 https://a.test"]).map((s) => s.replace(" │", "│"));
  const lower = box(30, "Changes", ["/not-the-same-link", "http://b.test", "some prose"]);
  assert.deepEqual(scan([...upper, ...lower, "footer https://c.test"]), [
    {row: 1, col: 4, url: "https://a.test"}, {row: 5, col: 1, url: "http://b.test"},
    {row: 8, col: 7, url: "https://c.test"},
  ]);
});
