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
  for (const parts of [["main.lua", ":20-22"], ["main.lua:", "20-22"], ["main.lua:2", "0-22"], ["main.lua:20-", "22"]]) {
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
