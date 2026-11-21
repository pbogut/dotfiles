// Also installed in pbogut-spaces so the sidebar and tab controller select the same definition.
export async function machinePaths(on, exec, local) {
  if (!on) return local;
  const result = await exec(
    "sh",
    [
      "-c",
      'printf "%s\\n" "$HOME" "${HERDR_APP_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/herdr-app}"',
    ],
    { on },
  );
  if (result.code !== 0) throw new Error(result.stderr.trim() || `Could not read paths on ${on}.`);
  const [home, appHome] = result.stdout.trimEnd().split("\n");
  if (!home?.startsWith("/") || !appHome?.startsWith("/"))
    throw new Error(`Invalid home paths on ${on}.`);
  return { home, appHome };
}

export const configuredName = (config) =>
  typeof config?.name === "string" ? config.name.trim() : "";

function originKey(url) {
  const match = url.includes("://")
    ? /^(?:https?|ssh|git):\/\/(?:[^/@]+@)?([^/?#@]+)\/([^?#]+)(?:[?#].*)?$/i.exec(url)
    : /^(?:[^/@:]+@)?([\w.-]+):(.+)$/.exec(url);
  if (!match) return null;
  const path = match[2].replace(/^\/+|\/+$/g, "").replace(/\.git$/i, "");
  return path ? `${match[1]}/${path}`.toLowerCase() : null;
}

async function selectGlobal(config, cwd, exec, on) {
  const object = (value) => value !== null && typeof value === "object" && !Array.isArray(value);
  if (!object(config)) throw new Error("Expected a JSON object.");
  const keys = Object.keys(config);
  const selector = (key) => key === "*" || key.includes("/");
  if (!keys.some(selector)) return config; // Original flat fallback.
  if (!keys.every(selector)) throw new Error('Put default project fields inside "*".');
  let key = "*";
  if (cwd && keys.some((key) => key !== "*")) {
    const origin = await exec("git", ["remote", "get-url", "origin"], { cwd, on });
    const exact = origin.code === 0 && originKey(origin.stdout.trim());
    if (exact) key = keys.find((candidate) => candidate.toLowerCase() === exact) ?? "*";
  }
  if (!Object.hasOwn(config, key)) return {};
  if (!object(config[key])) throw new Error(`Expected a project definition object at "${key}".`);
  return config[key];
}

export async function readDefinition(path, readTextFile, on, select) {
  try {
    const text = await readTextFile(path, { on });
    if (text === null) return null;
    const config = JSON.parse(text);
    return { path, config: select ? await select(config) : config };
  } catch (error) {
    throw new Error(`${path}: ${error.message ?? error}`);
  }
}

export async function projectDefinition(common, folder, exec, readTextFile, defaultPath, on) {
  if (common.endsWith("/.bare")) {
    const local = await readDefinition(
      `${common.slice(0, -6)}/herdr-project.json`,
      readTextFile,
      on,
    );
    if (local) return local;
  }
  const path = await defaultPath();
  return (
    path &&
    readDefinition(path, readTextFile, on, (config) =>
      selectGlobal(config, common && folder, exec, on),
    )
  );
}
