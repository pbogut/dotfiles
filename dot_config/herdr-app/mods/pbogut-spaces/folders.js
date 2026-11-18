// Absolute rules match a directory and its descendants. Relative rules match a
// sequence of directory components anywhere, independent of a machine's home.
export const DEFAULT_FOLDERS = { folders: ["work", "personal"], fallback: "other", rules: [] };
export const folderNames = (config) => [...config.folders, config.fallback];
export const ASSIGNMENTS = "pbogut.folders.assignments";
export const assignmentKey = (machine, directory) => directory
  ? JSON.stringify([machine ?? null, directory.replace(/\/+$/, "")]) : null;
export const spaceAssignmentKey = (machine, id) => JSON.stringify([machine ?? null, "space", id]);

export function parseFolders(text) {
  if (text === null) return DEFAULT_FOLDERS;
  const config = JSON.parse(text);
  const name = (value) => typeof value === "string" && value.trim() === value && value.length > 0;
  if (!config || !Array.isArray(config.folders) || !config.folders.every(name) || !name(config.fallback)) {
    throw new Error("Expected folders as names and a fallback folder name.");
  }
  const names = folderNames(config);
  if (new Set(names).size !== names.length) throw new Error("Folder names must be unique.");
  if (!Array.isArray(config.rules) || !config.rules.every(rule =>
    rule && name(rule.path) && rule.path !== "/" && !rule.path.includes("//") && names.includes(rule.folder)
    && !rule.path.split("/").some(part => part === "." || part === ".." || part === "~" || part.includes("*")))) {
    throw new Error("Each rule needs a directory path and a configured folder. Use paths without ~, wildcards or dot segments.");
  }
  return { ...config, rules: config.rules.map(rule => ({ ...rule, path: rule.path.replace(/\/+$/, "") })) };
}

export function matchFolder(root, config) {
  const path = (root || "").replace(/\/+$/, "");
  let best;
  for (const rule of config.rules) {
    const matches = rule.path.startsWith("/")
      ? path === rule.path || path.startsWith(`${rule.path}/`)
      : `/${path}/`.includes(`/${rule.path}/`);
    if (matches && (!best || rule.path.length > best.path.length)) best = rule;
  }
  return best?.folder ?? config.fallback;
}

// Keep native space indexes in the same order as the foldered sidebar. Retain
// order inside each folder, including the worktree rows already nested together.
export function orderFolders(rows, config, folderOf) {
  const machines = [...new Set(rows.map(row => row.w.machine ?? null))];
  return machines.flatMap(machine => {
    const mine = rows.filter(row => (row.w.machine ?? null) === machine);
    const tagged = mine.map(row => ({ row, folder: folderOf(row.w) }));
    return folderNames(config).flatMap(folder => tagged.filter(item => item.folder === folder).map(item => item.row));
  });
}
