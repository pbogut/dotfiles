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

export function commandFor(role, space, appHome, home) {
  const context = ["env", `HERDR_APP_HOME=${appHome}`, `HERDR_APP_SPACE_ID=${space.id}`];
  if (role.startsWith("oc-")) return ["opencode"];
  switch (role) {
    case "nvim": return [...context, "herdr-app-vim", "--start"];
    case "shell": case "shell-2": case "shell-3": return undefined;
    // Run without start-dev's Enter prompt; project-layout commands migrate separately.
    case "dev": return ["env", "-u", "HERDR_ENV", "zsh", "-ic", "if [[ -f Makefile ]]; then exec make dev; fi"];
    case "sql": return ["zsh", "-ic", "draft sql"];
    case "rest": return ["zsh", "-ic", "rest"];
    case "git": return [...context, "lazygit",
      `--use-config-file=${home}/.config/lazygit/config.yml,${home}/.config/lazygit/config-herdr-app.yml`];
    case "docker": return ["lazydocker"];
  }
}
