import assert from "node:assert/strict";
import { test } from "node:test";
import { wordTarget } from "../../../dot_config/herdr-app/mods/pbogut-copy/words.js";

test("Vim word starts and ends distinguish punctuation, underscores, and whitespace", () => {
  const text = "one_two...  three\tfour";
  for (const [motion, col, expected] of [
    ["w", 0, 7], ["w", 3, 7], ["w", 7, 12], ["w", 10, 12], ["w", 12, 18],
    ["e", 0, 6], ["e", 6, 9], ["e", 7, 9], ["e", 9, 16], ["e", 10, 16],
    ["b", 6, 0], ["b", 7, 0], ["b", 9, 7], ["b", 12, 7], ["b", 18, 12],
  ]) {
    assert.deepEqual(wordTarget(text, 80, 24, { row: 0, col }, motion),
      { row: 0, col: expected }, `${motion} at ${col}`);
  }
});

test("hard newlines break words, empty lines stop w/b, and e skips them", () => {
  const text = "one\n\n  two\nthree";
  for (const [motion, row, col, expectedRow, expectedCol] of [
    ["w", 0, 0, 1, 0], ["w", 1, 0, 2, 2], ["w", 2, 2, 3, 0],
    ["e", 0, 2, 2, 4], ["e", 2, 4, 3, 4],
    ["b", 2, 2, 1, 0], ["b", 1, 0, 0, 0], ["b", 3, 0, 2, 2],
  ]) {
    assert.deepEqual(wordTarget(text, 20, 10, { row, col }, motion),
      { row: expectedRow, col: expectedCol });
  }
});

test("soft wraps preserve words and exact-width hard lines advance only once", () => {
  const text = "abcdefghijk two\n1234567890\nnext";
  assert.deepEqual(wordTarget(text, 10, 10, { row: 0, col: 0 }, "e"), { row: 1, col: 0 });
  assert.deepEqual(wordTarget(text, 10, 10, { row: 0, col: 0 }, "w"), { row: 1, col: 2 });
  assert.deepEqual(wordTarget(text, 10, 10, { row: 1, col: 0 }, "b"), { row: 0, col: 0 });
  assert.deepEqual(wordTarget(text, 10, 10, { row: 2, col: 0 }, "w"), { row: 3, col: 0 });
});

test("Unicode letters, combining marks, wide glyphs, and emoji use terminal columns", () => {
  const text = "café e\u0301 界面 👩‍💻 next";
  for (const [motion, col, expected] of [
    ["w", 0, 5], ["w", 5, 7], ["e", 7, 9], ["w", 7, 12],
    ["w", 12, 15], ["b", 15, 12], ["b", 12, 7],
  ]) {
    assert.deepEqual(wordTarget(text, 40, 10, { row: 0, col }, motion),
      { row: 0, col: expected });
  }
  assert.deepEqual(wordTarget("abcd界 end", 5, 5, { row: 0, col: 0 }, "e"), { row: 1, col: 0 });
});

test("motions stay bounded and never reverse at the ends or in unused screen rows", () => {
  for (const motion of ["w", "e", "b"]) {
    assert.deepEqual(wordTarget("", 20, 10, { row: 0, col: 0 }, motion), { row: 0, col: 0 });
  }
  assert.deepEqual(wordTarget("one", 20, 10, { row: 0, col: 0 }, "b"), { row: 0, col: 0 });
  assert.deepEqual(wordTarget("one", 20, 10, { row: 0, col: 2 }, "e"), { row: 0, col: 2 });
  assert.deepEqual(wordTarget("one", 20, 10, { row: 9, col: 10 }, "w"), { row: 9, col: 10 });
  assert.deepEqual(wordTarget("one", 20, 10, { row: 9, col: 10 }, "b"), { row: 0, col: 0 });
  assert.deepEqual(wordTarget("one\noutside", 20, 1, { row: 0, col: 0 }, "w"), { row: 0, col: 2 });
});

test("W/E/B treat paths, URLs, and punctuation as whitespace-delimited words", () => {
  const text = "src/foo.js  https://a.b/x?q=1  next";
  for (const [motion, col, expected] of [
    ["W", 0, 12], ["W", 3, 12], ["W", 12, 31], ["W", 29, 31],
    ["E", 0, 9], ["E", 9, 28], ["E", 12, 28], ["E", 29, 34],
    ["B", 9, 0], ["B", 12, 0], ["B", 28, 12], ["B", 31, 12],
  ]) {
    assert.deepEqual(wordTarget(text, 80, 24, { row: 0, col }, motion),
      { row: 0, col: expected }, `${motion} at ${col}`);
  }
  assert.deepEqual(wordTarget("a/b.c\n\n  d/e", 4, 10, { row: 0, col: 0 }, "E"), { row: 1, col: 0 });
  assert.deepEqual(wordTarget("a/b.c\n\n  d/e", 4, 10, { row: 1, col: 0 }, "W"), { row: 2, col: 0 });
  assert.deepEqual(wordTarget("a/b.c\n\n  d/e", 4, 10, { row: 3, col: 2 }, "B"), { row: 2, col: 0 });
});

test("^ finds the first nonblank cell on the current physical row", () => {
  const text = "  one\n    界面\n\n   ";
  for (const [row, col, expected] of [
    [0, 0, 2], [0, 15, 2], [1, 0, 4], [1, 15, 4], [2, 5, 0], [3, 5, 2], [9, 5, 0],
  ]) {
    assert.deepEqual(wordTarget(text, 20, 10, { row, col }, "^"), { row, col: expected });
  }
  assert.deepEqual(wordTarget("abcdefghij  next", 5, 10, { row: 1, col: 4 }, "^"), { row: 1, col: 0 });
  assert.deepEqual(wordTarget("abcdefghij  next", 5, 10, { row: 2, col: 4 }, "^"), { row: 2, col: 2 });
});
