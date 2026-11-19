import assert from "node:assert/strict";
import { test } from "node:test";
import { taskHints } from "../../../dot_config/herdr-app/mods/pbogut-tabs/hints.js";

const keys = "fjdkslaurieowhgmvcn";
const automatic = n => Array.from({ length: n }, (_, i) => ({ name: `auto ${i}` }));
const autoHints = n => taskHints(automatic(n));
test("small lists use the preferred letters in project order", () => {
  assert.deepEqual(autoHints(0), []);
  assert.deepEqual(autoHints(7), [..."fjdksla"]);
  assert.deepEqual(autoHints(19), [...keys]);
  assert.deepEqual(autoHints(20), [...keys.slice(0, -1), "nf", "nj"]);
});

test("hints remain unambiguous and minimize equal-weight keypresses across depth boundaries", () => {
  for (const n of [21, 37, 38, 81, 360, 361, 362, 700]) {
    const hints = autoHints(n), set = new Set(hints);
    assert.equal(hints.length, n);
    assert.equal(set.size, n);
    for (const hint of hints) {
      assert.ok([...hint].every(c => keys.includes(c)));
      for (let i = 1; i < hint.length; i++) assert.ok(!set.has(hint.slice(0, i)));
    }
    const depth = Math.ceil(Math.log(n) / Math.log(keys.length));
    const short = Math.floor((keys.length ** depth - n) / (keys.length - 1));
    assert.equal(hints.reduce((sum, h) => sum + h.length, 0), n * depth - short);
  }
});

test("reserve custom hints before handing out automatic hints in project order", () => {
  const ssh = [{ name: "ssh ap", hint: "sa" }, { name: "ssh mp", hint: "sm" }];
  assert.deepEqual(taskHints([...automatic(5), ...ssh]), [..."fjdkl", "sa", "sm"]);
  const hints = taskHints([...ssh, ...automatic(20)]);
  assert.deepEqual(hints, ["sa", "sm", ...keys.replace("s", ""), "sf", "sj"]);
  const many = taskHints([...ssh, ...automatic(700)]);
  for (const h of many) assert.equal(many.filter(other => other.startsWith(h)).length, 1);
});

test("reserve letters outside the automatic alphabet and report exhausted keys", () => {
  const pinned = [...keys].map(hint => ({ name: hint, hint }));
  const hints = taskHints([...pinned, ...automatic(1)]);
  assert.equal(hints.length, 20);
  assert.ok(!keys.includes(hints.at(-1)));
  const all = [..."abcdefghijklmnopqrstuvwxyz"].map(hint => ({ name: hint, hint }));
  assert.throws(() => taskHints([...all, ...automatic(1)]), /no free keys/);
});
