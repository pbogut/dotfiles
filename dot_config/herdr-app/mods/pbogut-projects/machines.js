export function pickerMachines(machines, current) {
  return [...new Set([null, ...machines.filter((machine) => machine.layout === "ready")
    .map((machine) => machine.name), ...(current ? [current] : [])])];
}

// Mods cannot import across directories. Match pbogut-tabs/project.js.
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
