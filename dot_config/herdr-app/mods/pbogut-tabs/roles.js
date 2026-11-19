const order = ["nvim", "shell", "shell-2", "dev", "sql", "rest", "git", "docker", "oc", "shell-3"];

export function roleOf(name) {
  if (name === "opencode") return "oc-1";
  if (order.includes(name) && name !== "oc") return name;
  if (/^oc-[1-9][0-9]*$/.test(name) && Number.isSafeInteger(Number(name.slice(3)))) return name;
  return null;
}

export function compareTabs(a, b) {
  const rank = (tab) => {
    const role = tab.named && roleOf(tab.name);
    return role ? order.indexOf(role.startsWith("oc-") ? "oc" : role) : order.length;
  };
  return rank(a) - rank(b) || (rank(a) === order.indexOf("oc")
    ? Number(roleOf(a.name).slice(3)) - Number(roleOf(b.name).slice(3)) : 0);
}

export function commandFor(role, space, appHome, home, dev) {
  // The remote core's labels use its own IDs, without the App's machine prefix.
  const id = space.machine && space.id.startsWith(`${space.machine}/`) ? space.id.slice(space.machine.length + 1) : space.id;
  const context = ["env", `HERDR_APP_HOME=${appHome}`, `HERDR_APP_SPACE_ID=${id}`];
  if (role.startsWith("oc-")) return [...context, "herdr-app-opencode", "--start", role];
  const launch = [...context, "herdr-app-tab", "--start", role];
  switch (role) {
    case "nvim": return [...launch, "herdr-app-vim", "--start"];
    case "shell": case "shell-2": case "shell-3": return undefined;
    // Program-backed tabs close on exit, including the default make dev.
    case "dev": return [...launch, "env", "-u", "HERDR_ENV", "--",
      ...(dev ?? ["zsh", "-ic", "if [[ -f Makefile ]]; then exec make dev; fi"])];
    case "sql": return [...launch, "zsh", "-ic", "draft sql"];
    case "rest": return [...launch, "zsh", "-ic", "rest"];
    case "git": return [...launch, "lazygit",
      `--use-config-file=${home}/.config/lazygit/config.yml,${home}/.config/lazygit/config-herdr-app.yml`];
    case "docker": return [...launch, "lazydocker"];
  }
}
