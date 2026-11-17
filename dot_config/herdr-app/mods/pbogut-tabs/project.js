import { compareTabs, roleOf } from "./roles.js";

export const folderKey = (folder) => (folder ?? "").replace(/\/+$/, "") || "/";
export const orderKey = (space) => `pbogut-tabs.order.${space}`;

export function projectTabs(config) {
  if (!config || typeof config !== "object" || Array.isArray(config)) {
    throw new Error("Expected a JSON object.");
  }
  if (config.tabs === undefined) return [];
  if (!Array.isArray(config.tabs)) throw new Error('"tabs" must be an array of named tab roles.');
  const roles = config.tabs.map((name) => {
    const role = typeof name === "string" && roleOf(name);
    if (!role) throw new Error(`Unknown tab role: ${JSON.stringify(name)}.`);
    return role;
  });
  if (new Set(roles).size !== roles.length) throw new Error('"tabs" contains duplicate roles.');
  return roles;
}

export async function loadProjectTabs(folder, exec, readTextFile) {
  if (!folder) return [];
  const common = await exec("git", ["rev-parse", "--path-format=absolute", "--git-common-dir"], { cwd: folder });
  if (common.code !== 0) return [];
  const directory = common.stdout.trim();
  if (!directory.endsWith("/.bare")) return [];
  const path = `${directory.slice(0, -6)}/herdr-project.json`;
  try {
    const text = await readTextFile(path);
    return text === null ? [] : projectTabs(JSON.parse(text));
  } catch (error) {
    throw new Error(`${path}: ${error.message ?? error}`);
  }
}

export function projectOrder(a, b, roles) {
  const rank = (tab) => {
    const index = tab.named ? roles.indexOf(roleOf(tab.name)) : -1;
    return index < 0 ? roles.length : index;
  };
  return rank(a) - rank(b) || compareTabs(a, b);
}
