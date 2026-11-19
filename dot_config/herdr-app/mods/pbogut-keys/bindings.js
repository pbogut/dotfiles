export const prefixBindings = {
  c: ["tab.new"],
  v: ["pane.split", { direction: "right" }],
  s: ["pane.split", { direction: "down" }],
  x: ["pbogut-tabs.close-project"],
};

export const pickers = { spaces: "mod.open:pbogut-space-picker", agents: "pbogut-agents.picker" };

// Same unpinned hint order as the task picker. Mods cannot import across directories.
export function sidebarHints(ids) {
  const keys = "fjdkslaurieowhgmvcn";
  let leaves = [...keys];
  while (leaves.length < ids.length) {
    const split = Math.min(leaves.length, Math.ceil((ids.length - leaves.length) / (keys.length - 1)));
    leaves = [...leaves.slice(0, -split), ...leaves.slice(-split).flatMap(h => [...keys].map(k => h + k))];
  }
  return Object.fromEntries(ids.map((id, i) => [id, leaves[i]]));
}
