import { roleOf } from "./roles.js";
import { assignHints } from "./hints.js";

export const PROJECT_SPACES = "pbogut.projects.spaces";
export const isProject = (space, marked) => marked?.[space?.id] === true;
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

function validCommand(argv) {
  return Array.isArray(argv) && argv.length && argv.every(arg => typeof arg === "string" && !arg.includes("\0")) && argv[0];
}

export function projectConfig(config) {
  const tabs = projectTabs(config);
  const result = { tabs };
  if (config.dev !== undefined) {
    if (!validCommand(config.dev)) {
      throw new Error('"dev" must be a non-empty command array of strings.');
    }
    result.dev = config.dev;
  }
  if (config.tasks !== undefined) {
    if (!Array.isArray(config.tasks)) throw new Error('"tasks" must be an array.');
    const seen = new Set();
    result.tasks = config.tasks.map((task, index) => {
      const where = `tasks[${index}]`, name = task?.name;
      if (typeof name !== "string" || !name || name.trim() !== name || /[\x00-\x1f\x7f]/.test(name)) {
        throw new Error(`${where} requires a non-empty, single-line name.`);
      }
      if (roleOf(name) || ["setup", "teardown"].includes(name)) throw new Error(`${where}: reserved tab name "${name}".`);
      if (seen.has(name)) throw new Error(`${where}: duplicate task "${name}".`);
      seen.add(name);
      if (!validCommand(task.command)) throw new Error(`${where}.command must be a non-empty command array of strings.`);
      for (const flag of ["progress", "close"]) {
        if (task[flag] !== undefined && typeof task[flag] !== "boolean") throw new Error(`${where}.${flag} must be a boolean.`);
      }
      return { name, hint: task.hint, command: task.command, progress: task.progress ?? false, close: task.close ?? false };
    });
    const assigned = Object.fromEntries(result.tasks.filter(t => t.hint !== undefined).map(t => [t.name, t.hint]));
    try {
      const hints = assignHints([...seen], { assigned });
      for (const task of result.tasks) task.hint = hints[task.name];
    } catch (error) {
      throw new Error(`tasks: ${error.message}`);
    }
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
