import assert from "node:assert/strict";
import { test } from "node:test";
import { existingTargets } from "../../../dot_config/herdr-app/mods/pbogut-links/links.js";
import { openCodeLinks } from "../../../dot_config/herdr-app/mods/pbogut-links/opencode-wraps.js";
import { lazygitLinks } from "../../../dot_config/herdr-app/mods/pbogut-links/lazygit-wraps.js";

const chat = (rows) => openCodeLinks([...rows, "  ╹" + "▀".repeat(15)].join("\n"), 80, 0, 30, true);
const box = (rows) => ["╭────────────────╮", ...rows.map((s) => `│${s.padEnd(16)}│`), "╰────────────────╯"];
const panels = (left, right = left.map(() => "")) =>
  lazygitLinks(box(left).map((s, i) => s + box(right)[i]).join("\n"), 80, 0, 30, true);
const resolve = (targets, ...existing) => existingTargets(targets, (_cmd, args) => ({
  code: 0, stdout: existing.filter((p) => args.includes(p)).join("\n"),
}), {});

test("OpenCode joins three chat rows, measures wide glyphs, and ignores the sidebar", async () => {
  const screen = chat([
    "  ┃ 界 src/nested/    sidebar/",
    "  ┃ plugins/main.     unrelated.lua",
    "  ┃ lua:20-22.",
  ]);
  assert.deepEqual(await resolve(screen, "src/nested/plugins/main.lua", "lua", "sidebar/unrelated.lua"), [
    { row: 0, col: 7, path: "src/nested/plugins/main.lua", line: 20 },
  ]);
});

test("OpenCode joins a parenthesized file anchor across a directory or any part of the anchor", async () => {
  const dir = "app/Console/Commands/", file = "SubscriptionScheduleProcess.php", anchor = "#L306-L318";
  const path = dir + file;
  for (const cut of [dir.length, ...Array.from({ length: anchor.length }, (_, i) => path.length + i)]) {
    const token = path + anchor, first = "  payday processing (" + token.slice(0, cut);
    const rows = [first, "  " + token.slice(cut) + ") runs first.", "  ╹" + "▀".repeat(84)];
    const targets = openCodeLinks(rows.join("\n"), 100, 0, rows.length, true);
    assert.deepEqual(await resolve(targets, path), [
      { row: 0, col: first.indexOf(dir), path, line: 306 },
    ], `split after ${token.slice(0, cut)}`);
  }
});

test("OpenCode review table hints both Order.php ranges, even in scrollback without the prompt", async () => {
  const path = "app/Models/Order.php";
  const row = (priority, finding) => `  │ ${priority.padEnd(8)} │ ${finding.padEnd(50)} │  sidebar`;
  const table = [
    row("Priority", "Finding"),
    "  ├──────────┼────────────────────────────────────────────────────┤",
    row("P1", "Before releasing it. app/Models/"),
    row("", "Order.php:1231–1234"),
    "  ├──────────┼────────────────────────────────────────────────────┤",
    row("P1", "response. app/Models/Order.php:1459–1461"),
  ];
  for (const footer of [[], ["  ╹" + "▀".repeat(65)]]) {
    const screen = openCodeLinks([...table, ...footer].join("\n"), 90, 0, 20, true);
    assert.deepEqual(await resolve(screen, path), [
      { row: 2, col: table[2].indexOf("app/"), path, line: 1231 },
      { row: 5, col: table[5].indexOf("app/"), path, line: 1459 },
    ]);
  }
});

test("table file hints cannot join through a divider or into a different column", async () => {
  const screen = [
    "  │ src/ │ file/  │",
    "  │      │ x.lua  │",
    "  ├──────┼────────┤",
    "  │      │ main/  │",
    "  ├──────┼────────┤",
    "  │      │ x.lua  │",
  ];
  const targets = openCodeLinks(screen.join("\n"), 60, 0, 10, true);
  assert.deepEqual(await resolve(targets, "src/x.lua", "main/x.lua", "file/x.lua"), [
    { row: 0, col: 11, path: "file/x.lua", line: null },
  ]);
});

test("Lazygit leaves the short file at its cell and puts the joined file on the continuation", async () => {
  const screen = panels(["", ""], ["see src/name", ".lua:20-22"]);
  const long = "src/name.lua";
  assert.deepEqual(await resolve(screen, "src/name", long), [
    { row: 1, col: 23, path: "src/name", line: null },
    { row: 2, col: 19, path: long, line: 20 },
  ]);
  assert.deepEqual(await resolve(screen, long), [{ row: 1, col: 23, path: long, line: 20 }]);
  assert.deepEqual(await resolve(screen, "src/name"), [{ row: 1, col: 23, path: "src/name", line: null }]);
});

test("a split line suffix gives one hint for the file, with the reconstructed line", async () => {
  for (const parts of [["main.lua", ":20-22"], ["main.lua:", "20-22"], ["main.lua:2", "0-22"],
    ["main.lua:20-", "22"], ["main.lua:20–", "22"], ["main.lua:20", "–22"]]) {
    const screen = panels([parts[0].padStart(16), parts[1]]);
    assert.deepEqual(await resolve(screen, "main.lua"), [
      { row: 1, col: 17 - parts[0].length, path: "main.lua", line: 20 },
    ]);
  }
});

test("do not join across panels, chat blocks, blank rows, or ordinary prose line breaks", async () => {
  for (const screen of [
    panels(["src/", ""], ["", "main.lua"]),
    chat(["  ┃ src/", "    main.lua"]), chat(["  src/", "", "  main.lua"]),
    chat(["  log", "  in here"]), panels(["log", "in here"]),
  ]) assert.deepEqual(await resolve(screen, "src/main.lua", "login"), []);
});

test("a filename inside a URL cannot start a wrapped file hint", async () => {
  const screen = chat(["  https://x/(src/", "  main.lua"]);
  assert.deepEqual((await resolve(screen, "src/main.lua")).filter((t) => t.path), []);
});
