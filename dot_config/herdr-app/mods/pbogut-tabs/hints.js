const letters = "fjdkslaurieowhgmvcn";

// At each depth, keep the easiest free keys short. Split the last ones only
// when the already-reserved branches won't have enough children for the rest.
function automatic(count, keys, taken, prefixes) {
  const hints = [];
  const free = h => !taken.has(h) && !prefixes.has(h);
  if (keys.length < 2) return keys.filter(free).slice(0, count);
  const children = h => keys.map(k => h + k);
  let level = keys;
  while (level.length && hints.length < count) {
    const available = level.filter(free), remaining = count - hints.length;
    if (remaining <= available.length) return hints.concat(available.slice(0, remaining));
    const forced = level.filter(h => prefixes.has(h)).flatMap(children);
    const split = Math.max(0, Math.ceil((remaining - available.length - forced.filter(free).length) / (keys.length - 1)));
    const keep = Math.max(0, available.length - split);
    hints.push(...available.slice(0, keep));
    level = forced.concat(available.slice(keep).flatMap(children));
  }
  return hints;
}

// Assign prefix-free hints in display order. Skipped letters cannot appear
// anywhere; an assigned hint reserves only itself and conflicting prefixes.
export function assignHints(ids, { skipKeys = "", assigned = {} } = {}) {
  const pinned = new Map(Object.entries(assigned));
  const taken = new Map(), prefixes = new Map();
  for (const name of ids) {
    const hint = pinned.get(name);
    if (hint === undefined) continue;
    if (typeof hint !== "string" || !hint.length || /[^a-z]/.test(hint))
      throw new Error(`hint for "${name}" must contain only lowercase letters a-z.`);
    if ([...hint].some(key => skipKeys.includes(key)))
      throw new Error(`hint "${hint}" for "${name}" contains a skipped key.`);
    let conflict = taken.get(hint) ?? prefixes.get(hint);
    for (let i = 1; i < hint.length && !conflict; i++) conflict = taken.get(hint.slice(0, i));
    if (conflict) throw new Error(`hint "${hint}" for "${name}" conflicts with "${conflict}".`);
    taken.set(hint, name);
    for (let i = 1; i < hint.length; i++) prefixes.set(hint.slice(0, i), name);
  }
  const count = ids.length - taken.size;
  const allowed = keys => [...keys].filter(key => !skipKeys.includes(key));
  let auto = automatic(count, allowed(letters), taken, prefixes);
  if (auto.length < count) auto = automatic(count, allowed(letters + "bptqxyz"), taken, prefixes);
  if (auto.length < count) throw new Error("custom hints leave no free keys for automatic hints.");
  let next = 0;
  return Object.fromEntries(ids.map(id => [id, pinned.get(id) ?? auto[next++]]));
}
