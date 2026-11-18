import { roleOf } from "./roles.js";

export const folderKey = (folder) => (folder ?? "").replace(/\/+$/, "") || "/";

// Mods cannot import across directories. Match pbogut-projects/machines.js.
export async function machinePaths(on, exec, local) {
  if (!on) return local;
  const result = await exec("sh", ["-c",
    'printf "%s\\n" "$HOME" "${HERDR_APP_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/herdr-app}"',
  ], { on });
  if (result.code !== 0) throw new Error(result.stderr.trim() || `Could not read paths on ${on}.`);
  const [home, appHome] = result.stdout.trimEnd().split("\n");
  if (!home?.startsWith("/") || !appHome?.startsWith("/")) throw new Error(`Invalid home paths on ${on}.`);
  return { home, appHome };
}

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
  const result = { tabs };
  if (config.dev !== undefined) {
    if (!Array.isArray(config.dev) || !config.dev.length ||
      config.dev.some((arg) => typeof arg !== "string" || arg.includes("\0")) || !config.dev[0]) {
      throw new Error('"dev" must be a non-empty command array of strings.');
    }
    result.dev = config.dev;
  }
  if (config.setup !== undefined) {
    const setup = config.setup;
    if (!setup || typeof setup !== "object" || Array.isArray(setup) ||
        typeof setup.script !== "string" || !setup.script.trim() || setup.script.includes("\0")) {
      throw new Error('"setup" requires a non-empty "script" path.');
    }
    result.setup = { script: setup.script };
  }
  if (config.teardown !== undefined) {
    const teardown = config.teardown;
    if (!teardown || typeof teardown !== "object" || Array.isArray(teardown) ||
        typeof teardown.script !== "string" || !teardown.script.trim() || teardown.script.includes("\0")) {
      throw new Error('"teardown" requires a non-empty "script" path.');
    }
    result.teardown = { script: teardown.script };
  }
  return result;
}

export async function loadProjectConfig(folder, exec, readTextFile, defaultPath, on = null) {
  const paths = [];
  if (folder) {
    const common = await exec("git", ["rev-parse", "--path-format=absolute", "--git-common-dir"], { cwd: folder, on });
    const directory = common.code === 0 ? common.stdout.trim() : "";
    if (directory.endsWith("/.bare")) paths.push(`${directory.slice(0, -6)}/herdr-project.json`);
  }
  if (defaultPath) paths.push(defaultPath);
  for (const path of paths) {
    try {
      const text = await readTextFile(path, { on });
      if (text !== null) {
        const config = projectConfig(JSON.parse(text));
        for (const hook of ["setup", "teardown"]) {
          if (config[hook]) config[hook].directory = path.slice(0, path.lastIndexOf("/")) || "/";
        }
        return config;
      }
    } catch (error) {
      throw new Error(`${path}: ${error.message ?? error}`);
    }
  }
  return { tabs: [] };
}
