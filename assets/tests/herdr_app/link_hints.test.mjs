import assert from "node:assert/strict";
import { test } from "node:test";
import { grid, visibleLinks } from "../../../dot_config/herdr-app/mods/pbogut-links/links.js";

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
