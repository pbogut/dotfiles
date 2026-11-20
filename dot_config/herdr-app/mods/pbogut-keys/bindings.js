export const prefixBindings = {
  c: ["tab.new"],
  v: ["pane.split", { direction: "right" }],
  s: ["pane.split", { direction: "down" }],
  x: ["pbogut-tabs.close-project"],
};

export const pickers = { spaces: "pbogut-space-picker", agents: "pbogut-agents" };

// Task-picker order, except j/k are reserved for moving the sidebar highlight.
export function sidebarHints(ids) {
  const keys = "fdslaurieowhgmvcn";
  let leaves = [...keys];
  while (leaves.length < ids.length) {
    const split = Math.min(leaves.length, Math.ceil((ids.length - leaves.length) / (keys.length - 1)));
    leaves = [...leaves.slice(0, -split), ...leaves.slice(-split).flatMap(h => [...keys].map(k => h + k))];
  }
  return Object.fromEntries(ids.map((id, i) => [id, leaves[i]]));
}
