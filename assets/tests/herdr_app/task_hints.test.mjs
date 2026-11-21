import assert from "node:assert/strict";
import { test } from "node:test";
import { assignHints } from "../../../dot_config/herdr-app/mods/pbogut-tabs/hints.js";

const keys = "fjdkslaurieowhgmvcn";
const ids = n => Array.from({ length: n }, (_, i) => `auto ${i}`);
const autoHints = n => Object.values(assignHints(ids(n)));
test("sidebar hints follow display order, reserve j/k, and split the last key first", () => {
  assert.deepEqual(assignHints(["work", "personal", "other"], { skipKeys: "jk" }), { work: "f", personal: "d", other: "s" });
  const ids = Array.from({ length: 18 }, (_, i) => `space-${i}`);
  const hints = assignHints(ids, { skipKeys: "jk" });
  assert.deepEqual(ids.map(id => hints[id]), [..."fdslaurieowhgmvc", "nf", "nd"]);
});

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
  const assigned = { "ssh ap": "sa", "ssh mp": "sm" }, ssh = Object.keys(assigned);
  assert.deepEqual(Object.values(assignHints([...ids(5), ...ssh], { assigned })), [..."fjdkl", "sa", "sm"]);
  const hints = Object.values(assignHints([...ssh, ...ids(20)], { assigned }));
  assert.deepEqual(hints, ["sa", "sm", ...keys.replace("s", ""), "sf", "sj"]);
  const many = Object.values(assignHints([...ssh, ...ids(700)], { assigned }));
  for (const h of many) assert.equal(many.filter(other => other.startsWith(h)).length, 1);
});

test("reserve letters outside the automatic alphabet and report exhausted keys", () => {
  const pin = alphabet => Object.fromEntries([...alphabet].map(key => [key, key]));
  const hints = Object.values(assignHints([...keys, "auto"], { assigned: pin(keys) }));
  assert.equal(hints.length, 20);
  assert.ok(!keys.includes(hints.at(-1)));
  const all = "abcdefghijklmnopqrstuvwxyz";
  assert.throws(() => assignHints([...all, "auto"], { assigned: pin(all) }), /no free keys/);
});

test("skipped keys stay excluded even in pinned hints and fallback allocations", () => {
  assert.throws(() => assignHints(["test"], { assigned: { test: "fj" }, skipKeys: "jk" }), /skipped key/);
  const preferred = [...keys].filter(key => !"jk".includes(key));
  const assigned = Object.fromEntries(preferred.map(key => [key, key]));
  const hints = assignHints([...preferred, ...ids(20)], { assigned, skipKeys: "jk" });
  assert.ok(Object.values(hints).every(hint => !/[jk]/.test(hint)));
});
