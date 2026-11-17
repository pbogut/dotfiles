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

export function projectConfig(config) {
  const tabs = projectTabs(config);
  if (config.dev === undefined) return { tabs };
  if (!Array.isArray(config.dev) || !config.dev.length ||
      config.dev.some((arg) => typeof arg !== "string" || arg.includes("\0")) || !config.dev[0]) {
    throw new Error('"dev" must be a non-empty command array of strings.');
  }
  return { tabs, dev: config.dev };
}

export async function loadProjectConfig(folder, exec, readTextFile, defaultPath) {
  const paths = [];
  if (folder) {
    const common = await exec("git", ["rev-parse", "--path-format=absolute", "--git-common-dir"], { cwd: folder });
    const directory = common.code === 0 ? common.stdout.trim() : "";
    if (directory.endsWith("/.bare")) paths.push(`${directory.slice(0, -6)}/herdr-project.json`);
  }
  if (defaultPath) paths.push(defaultPath);
  for (const path of paths) {
    try {
      const text = await readTextFile(path);
      if (text !== null) return projectConfig(JSON.parse(text));
    } catch (error) {
      throw new Error(`${path}: ${error.message ?? error}`);
    }
  }
  return { tabs: [] };
}

export function projectOrder(a, b, roles) {
  const rank = (tab) => {
    const index = tab.named ? roles.indexOf(roleOf(tab.name)) : -1;
    return index < 0 ? roles.length : index;
  };
  return rank(a) - rank(b) || compareTabs(a, b);
}
