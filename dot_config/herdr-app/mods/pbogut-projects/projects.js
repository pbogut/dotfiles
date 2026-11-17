export const folderKey = (folder) => (folder ?? "").replace(/\/+$/, "") || "/";

export function projectLabel(folder, config) {
  const root = folderKey(config.root);
  const path = folderKey(folder);
  const relative = path.startsWith(`${root}/`) ? path.slice(root.length + 1) : path;
  const parts = relative.split("/");
  return parts.map((part, index) => index === parts.length - 1 ? part
    : config.aliases?.[part] ? `${config.aliases[part]}󰿟` : `${part}/`).join("");
}

export function projectRows(spaces, projects, config, query = "") {
  const open = spaces.map((space) => ({
    id: space.id, folder: space.folder, machine: space.machine, active: space.active,
    label: space.named || !space.folder ? space.name : projectLabel(space.folder, config),
  }));
  const seen = new Set(open.filter((row) => !row.machine && row.folder).map((row) => folderKey(row.folder)));
  const rows = [...open];
  for (const folder of projects) {
    if (!folder.startsWith("/") || seen.has(folderKey(folder))) continue;
    seen.add(folderKey(folder));
    rows.push({ folder, machine: null, label: projectLabel(folder, config) });
  }
  const words = query.toLowerCase().trim().split(/\s+/).filter(Boolean);
  return rows.filter((row) => words.every((word) =>
    `${row.label} ${row.folder ?? ""} ${row.folder ? projectLabel(row.folder, config) : ""} ${row.machine ?? ""}`
      .toLowerCase().includes(word)));
}

export function openProject(row, spaces) {
  const existing = row.id ? spaces.find((space) => space.id === row.id)
    : spaces.find((space) => !space.machine && folderKey(space.folder) === folderKey(row.folder));
  if (existing) return ["space.select", { id: existing.id }];
  if (row.id) return null; // A space closed while the picker was open.
  return ["space.new", { name: row.label, folder: row.folder, machine: "" }];
}
