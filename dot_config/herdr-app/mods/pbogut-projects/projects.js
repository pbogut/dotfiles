export const folderKey = (folder) => (folder ?? "").replace(/\/+$/, "") || "/";

export function projectLabel(folder, config) {
  const root = folderKey(config.root);
  const path = folderKey(folder);
  const relative = path.startsWith(`${root}/`) ? path.slice(root.length + 1) : path;
  const parts = relative.split("/");
  return parts
    .map((part, index) =>
      index === parts.length - 1
        ? part
        : config.aliases?.[part]
          ? `${config.aliases[part]}󰿟`
          : `${part}/`,
    )
    .join("");
}

export function projectRows(spaces, projects, config, query = "", machine = null, marked = {}) {
  const open = spaces
    .filter((space) => marked?.[space.id] === true && (space.machine ?? null) === machine)
    .map((space) => ({
      id: space.id,
      folder: space.folder,
      machine: space.machine,
      active: space.active,
      label: space.named || !space.folder ? space.name : projectLabel(space.folder, config),
    }));
  const seen = new Set(open.filter((row) => row.folder).map((row) => folderKey(row.folder)));
  const rows = [...open];
  for (const folder of projects) {
    if (!folder.startsWith("/") || seen.has(folderKey(folder))) continue;
    seen.add(folderKey(folder));
    rows.push({ folder, machine, label: projectLabel(folder, config) });
  }
  const words = query.toLowerCase().trim().split(/\s+/).filter(Boolean);
  return rows.filter((row) =>
    words.every((word) =>
      `${row.label} ${row.folder ?? ""} ${row.folder ? projectLabel(row.folder, config) : ""} ${row.machine ?? ""}`
        .toLowerCase()
        .includes(word),
    ),
  );
}

export function openProject(row, spaces, marked = {}) {
  const machine = row.machine ?? null;
  const projects = spaces.filter((space) => marked?.[space.id] === true);
  const existing = row.id
    ? projects.find((space) => space.id === row.id)
    : projects.find(
        (space) =>
          (space.machine ?? null) === machine && folderKey(space.folder) === folderKey(row.folder),
      );
  if (existing) {
    if (!existing.folder?.startsWith("/")) return ["space.select", { id: existing.id }];
    return [
      `pbogut-tabs.project@${encodeURIComponent(
        JSON.stringify({
          id: existing.id,
          folder: existing.folder,
          label: row.label,
          machine,
        }),
      )}`,
    ];
  }
  if (row.id) return null; // A space closed while the picker was open.
  return [
    `pbogut-tabs.project@${encodeURIComponent(JSON.stringify({ folder: row.folder, label: row.label, machine }))}`,
  ];
}
