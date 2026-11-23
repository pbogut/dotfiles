import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { test } from "node:test";
import { existingTargets, grid, visibleLinks } from "../../../dot_config/herdr-app/mods/pbogut-links/links.js";
import { openCodeLinks } from "../../../dot_config/herdr-app/mods/pbogut-links/opencode-wraps.js";
import { lazygitLinks } from "../../../dot_config/herdr-app/mods/pbogut-links/lazygit-wraps.js";

test("only label visible printed links, keeping a wrapped URL whole", () => {
  const screen = "https://old.test\n界e\u0301 (https://a.test/(x)).\n    https://b.test?a=1&b=2!\nhttps://off.test";
  assert.deepEqual(visibleLinks(screen, 20, 1, 4), [
    { row: 0, col: 5, url: "https://a.test/(x)" },
    { row: 2, col: 4, url: "https://b.test?a=1&b=2" },
  ]);
});

test("labels use the cell pitch rather than accumulating the spare pixels", () => {
  assert.deepEqual(grid({left: 269, width: 1018, height: 730}, 101, 34, 1, 16),
    {left: 269, top: 8, w: 10, h: 21});
  assert.equal(grid({left: 0, width: 1010, height: 730}, 106, 34, 1, 16).w, 9.5);
});

test("visible file hints use the pane directory, check each path once, and keep the start line", async () => {
  const cwd = fileURLToPath(new URL("../../../dot_config/herdr-app", import.meta.url));
  const path = "mods/pbogut-links/main.js";
  const text = [
    "offscreen.js", `界 \`${path}:20-22\``, `${path}:7 ./README.md.`,
    `mods missing.js /README.md ~/README.md (https://test/?file=./README.md)`,
  ].join("\n");
  let calls = 0;
  const targets = await existingTargets(visibleLinks(text, 80, 1, 3, true), (cmd, args, options) => {
    calls++;
    assert.equal(args.filter((s) => s === path).length, 1);
    assert.ok(!args.includes("offscreen.js"));
    const { stdout, status: code } = spawnSync(cmd, args, { ...options, encoding: "utf8" });
    return { stdout, code };
  }, { cwd });
  assert.equal(calls, 1);
  assert.deepEqual(targets, [
    { row: 0, col: 4, path, line: 20 },
    { row: 1, col: 0, path, line: 7 },
    { row: 1, col: path.length + 3, path: "./README.md", line: null },
    { row: 2, col: text.split("\n")[3].indexOf("https"), url: "https://test/?file=./README.md" },
  ]);
});

test("a wrapped URL continuation does not also become a file hint", () => {
  const chat = ["  http://", "  README.md", "  ╹▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀"].join("\n");
  assert.deepEqual(openCodeLinks(chat, 40, 0, 3, true), [
    { row: 0, col: 2, url: "http://README.md" },
  ]);
  const panel = ["╭───────────╮", "│https://x/a│", "│README.md  │", "│           │", "│main.lua:4 │", "╰───────────╯"].join("\n");
  assert.deepEqual(lazygitLinks(panel, 40, 0, 6, true), [
    { row: 1, col: 1, url: "https://x/a" },
    { row: 2, col: 1, url: "https://x/aREADME.md" },
    { row: 4, col: 1, path: "main.lua", line: 4 },
  ]);
});
