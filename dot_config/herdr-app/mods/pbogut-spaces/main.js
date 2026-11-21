// Workspace spaces: project names and initials, worktrees under their checkout,
// grouped by machine when more than one is known. The right side shows the
// terminal's current branch without its date prefix, plus ahead/behind counts.
// Click to switch, right-click for its menu, drag to reorder.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, ScrollHandle } from "gpui-base";
import { spaces, machines, panes, run, openOverlay, exec, hc, appHome, readTextFile, theme, shared, setShared, watchFolder, window, layout, checking, nextCommand, notify, props } from "herdr";
import { ASSIGNMENTS, assignmentKey, spaceAssignmentKey, DEFAULT_FOLDERS, folderNames, parseFolders, matchFolder, orderFolders } from "./folders.js";
import SpaceMenu from "./menu.js";

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

// The sidebar's rail goes by its width, not a flag: dragging its edge narrows it too.
const narrow = () => (find(layout(), "sidebar")?.size?.px ?? Infinity) < 160;

// Where a space is now: its first terminal's live folder, else where it was made.
// `ps`: panes(), read once by the caller (each read copies every pane).
function place(s, ps) {
  const tabs = new Set((s.tabs ?? []).map((c) => c.id));
  return ps.find((p) => tabs.has(p.tab) && p.cwd)?.cwd || s.folder;
}
const rowHeight = ({ tree }) => (tree ? 28 : 30);
const RAIL_CELL = 32;
// A space's name and its git tail never shrink below this, so a short one ("api")
// stays readable instead of turning into an ellipsis next to a long branch.
const SIDE_MIN = 48;
const railCell = (el) => h_flex().flex_none().justify_center().child(el);
const where = (s, ps) => JSON.stringify([s.machine ?? null, place(s, ps)]);
const base = (path) => path.replace(/\/+$/, "").split("/").pop();
const projectKey = (s) => JSON.stringify([s.machine ?? null, s.folder]);
const isProject = (s) => shared("pbogut.projects.spaces")?.[s.id] === true;

function projectName(common, folder, fallback = "") {
  const repo = common.replace(/\/+$/, "").replace(/\/\.(git|bare)$/, "");
  return repo ? base(repo).replace(/\.git$/, "") : base(folder || "") || fallback;
}

// Changes made outside Herdr (an editor's save, a commit in another app): looked
// for this often, in repos the list shows, while the window is in front.
const FALLBACK = 60000;
// Places looked at together (two git runs each). All at once, a few hundred spaces
// run out of the app's open files (256 when started from the Dock on macOS) or
// past a machine core's 16 running execs, and those spaces wait for FALLBACK.
const AT_ONCE = 6;

// Both runs, finished: a place isn't done while one of its runs still holds a slot.
async function both(a, b) {
  const done = await Promise.allSettled([a, b]);
  const failed = done.find((d) => d.status === "rejected");
  if (failed) throw failed.reason;
  return done.map((d) => d.value);
}

// What a stored color name looks like on an avatar (the same in every mod
// that draws space avatars): one strong color per hue, light and dark alike.
const MARK = { ansi6: "#22a99a", ansi3: "#e3814f", ansi4: "#5b8def", ansi5: "#8b7cf6", ansi2: "#3fae6a", ansi1: "#d9649a" };

// A space speaks up only when something in it needs you.
export function glyph(status) {
  return status === "blocked" || status === "done" ? "●" : "·";
}

export function tone(t, status) {
  return t[status] ?? t.unknown;
}

export default class Spaces extends View {
  init(_props, cx) {
    if (props()?.spaceMenu) {
      this.popup = new SpaceMenu(props(), cx);
      return;
    }
    this.git = {}; // where() -> { name, branch, ahead, behind, repo, linked }, null: not a repo
    this.checked = {}; // where() -> when it was last looked at
    this.unsure = new Set(); // where()s git couldn't answer for (a machine away)
    this.pending = new Set(); // where()s to look at next
    this.busy = {}; // pane -> an agent working or a program in front of its shell
    this.ready = {}; // machine -> its layout was readable at the last look
    this.at = {}; // space -> its where() at the last look
    this.watching = new Map(); // local repos' pending folder watches
    this.projects = new Map(); // configured machine/folder -> { name, root, directory }
    this.projectReloads = new Set();
    // Spaces made while this runs wait (at most a moment) for their git, so a
    // worktree appears under its repo instead of jumping there.
    this.shown = new Set(spaces().map((s) => s.id));
    this.born = {};
    this.pressed = null;
    this.over = null;
    this.overFolder = null;
    this.scroll = ScrollHandle.new(); // the list's position: the active space is brought into view through it
    this.activeAt = -1; // the active space's place among the list's children (headers and rows), -1 when not drawn
    this.machines = [];
    try {
      this.reconnecting = JSON.parse(localStorage.getItem("machines.reconnecting") ?? "{}");
      if (!this.reconnecting || typeof this.reconnecting !== "object" || Array.isArray(this.reconnecting)) this.reconnecting = {};
      for (const state of Object.values(this.reconnecting)) state.busy = false;
    } catch { this.reconnecting = {}; }
    try { this.folded = new Set(JSON.parse(localStorage.getItem("machines.folded") ?? "[]")); } catch { this.folded = new Set(); }
    try { this.foldersFolded = new Set(JSON.parse(localStorage.getItem("pbogut.folders.folded") ?? "[]")); } catch { this.foldersFolded = new Set(); }
    this.showEmptyFolders = localStorage.getItem("pbogut.folders.show-empty") === "true";
    this.folderConfig = DEFAULT_FOLDERS;
    if (!checking()) {
      this.reloadFolders(cx);
      cx.timer.every(5000, cx => this.reloadFolders(cx));
    }
    this.refreshMachines(cx);
    cx.timer.every(15000, cx => this.refreshMachines(cx));
    // Refresh only when the refs could have changed (see `due`).
    cx.timer.every(250, (cx) => this.checkNew(cx));
    if (!checking()) cx.spawn(async cx => {
      for (;;) {
        const command = await nextCommand();
        if (!command.startsWith("reload@")) continue;
        try {
          const project = JSON.parse(decodeURIComponent(command.slice(7)));
          if (!project.folder?.startsWith("/")) continue;
          this.projectReloads.add(projectKey(project));
          this.refreshProjects(spaces(), cx);
        } catch {}
      }
    });
  }

  reloadFolders(cx) {
    if (this.readingFolders) return;
    this.readingFolders = true;
    cx.spawn(async cx => {
      const before = JSON.stringify([this.folderConfig, this.folderError]);
      try {
        this.folderConfig = parseFolders(await readTextFile(`${appHome()}/folders.json`));
        this.folderError = null;
      } catch (error) {
        this.folderError = `folders.json: ${error.message ?? error}`;
      } finally {
        this.readingFolders = false;
      }
      if (before !== JSON.stringify([this.folderConfig, this.folderError])) cx.notify();
    });
  }

  folderFor(space) {
    const chosen = (shared(ASSIGNMENTS) ?? {})[this.folderKey(space)];
    if (folderNames(this.folderConfig).includes(chosen)) return chosen;
    return matchFolder(this.projects.get(projectKey(space))?.root ?? space.folder, this.folderConfig);
  }

  folderKey(space) {
    return isProject(space) ? assignmentKey(space.machine, this.projects.get(projectKey(space))?.directory)
      : spaceAssignmentKey(space.machine, space.id);
  }

  assignFolder(space, folder, cx) {
    const project = isProject(space);
    if (!folderNames(this.folderConfig).includes(folder) || (project && !space.folder)) return;
    cx.spawn(async cx => {
      try {
        let key = this.folderKey(space);
        if (project && !key) {
          const result = await exec("git", ["rev-parse", "--path-format=absolute", "--git-common-dir"], {
            cwd: space.folder, on: space.machine ?? null,
          });
          if (result.code !== 0 && !/not a git repository/i.test(result.stderr)) {
            throw new Error(result.stderr || "Could not find project root.");
          }
          const directory = (result.code === 0 ? result.stdout.replace(/\n$/, "") : space.folder).replace(/\/+$/, "");
          if (!directory) throw new Error("Could not find project root.");
          key = assignmentKey(space.machine, directory);
          this.projectReloads.add(projectKey(space));
        }
        // A drop that finishes after its space closed or changed identity is stale.
        if (!spaces().some(s => s.id === space.id && projectKey(s) === projectKey(space) && isProject(s) === project)) return;
        setShared(ASSIGNMENTS, { ...(shared(ASSIGNMENTS) ?? {}), [key]: folder });
        this.foldersFolded.delete(JSON.stringify([space.machine ?? null, folder]));
        localStorage.setItem("pbogut.folders.folded", JSON.stringify([...this.foldersFolded]));
        cx.notify();
      } catch (error) {
        notify({ title: "Could not move space", body: String(error.message ?? error), level: "error" });
      }
    });
  }

  checkNew(cx) {
    const now = Date.now();
    const sp = spaces();
    for (const s of sp) if (!this.shown.has(s.id)) this.born[s.id] ??= now;
    const due = this.due(now, sp, panes());
    if (due.size) this.refreshGit(due, cx);
    if (sp.some((s) => !this.shown.has(s.id)) || this.orderingDue(now)) cx.notify();
  }

  // Every space needs its Git root for folder matching. Only marked projects
  // read names from herdr-project.json; ordinary spaces keep Herdr's live name.
  refreshProjects(sp, cx) {
    if (this.refreshingProjects) return;
    const keys = new Set(sp.filter(s => s.folder).map(projectKey));
    const projectKeys = new Set(sp.filter(s => s.folder && isProject(s)).map(projectKey));
    for (const key of this.projects.keys()) if (!keys.has(key)) this.projects.delete(key);
    for (const key of this.projectReloads) if (!keys.has(key)) this.projectReloads.delete(key);
    const due = [...keys].filter(key => !this.projects.has(key) || this.projectReloads.has(key)
      || (projectKeys.has(key) && !this.projects.get(key).nameLoaded));
    if (!due.length) return;
    this.refreshingProjects = true;
    cx.spawn(async cx => {
      let next = 0;
      await Promise.all(Array.from({ length: Math.min(AT_ONCE, due.length) }, async () => {
        while (next < due.length) {
          const key = due[next++];
          const [on, cwd] = JSON.parse(key);
          const reload = this.projectReloads.delete(key);
          const entry = { ...this.projects.get(key), nameLoaded: projectKeys.has(key) };
          try {
            const r = await exec("git", ["rev-parse", "--path-format=absolute", "--git-common-dir"], { cwd, on });
            if (r.code !== 0 && !/not a git repository/i.test(r.stderr)) throw new Error(r.stderr || "Could not find project root.");
            const common = r.code === 0 ? r.stdout.replace(/\n$/, "") : "";
            const fallback = projectName(common, cwd);
            entry.directory = (common || cwd).replace(/\/+$/, "");
            entry.root = (common || cwd).replace(/\/+$/, "").replace(/\/\.(git|bare)$/, "");
            entry.name ??= fallback;
            if (entry.nameLoaded) {
              const path = `${entry.root}/herdr-project.json`;
              try {
                const config = JSON.parse(await readTextFile(path, { on }));
                entry.name = typeof config?.name === "string" && config.name.trim() ? config.name.trim() : fallback;
              } catch (error) {
                throw new Error(`${path}: ${error.message ?? error}`);
              }
            }
            if (reload) {
              for (const [otherKey, other] of this.projects) {
                if (JSON.parse(otherKey)[0] === on && other.root === entry.root) other.name = entry.name;
              }
            }
          } catch (error) {
            // Keep the last name until an explicit reload succeeds.
            if (reload) notify({ title: "Could not reload project name", body: String(error.message ?? error), level: "error" });
          }
          this.projects.set(key, entry);
        }
      }));
      this.refreshingProjects = false;
      cx.notify();
    });
  }

  // Places whose git could have changed: new ones (a new space, a cd), where a
  // command or an agent's turn just ended (a checkout, a commit, edits), those on
  // a machine that is back, and repos in view whose fallback is due.
  due(now, sp, ps) {
    // Moved there: what it knew of that place may be old.
    const at = {};
    for (const s of sp) at[s.id] = where(s, ps);
    const keys = new Set(Object.values(at).filter((k) => JSON.parse(k)[1]));
    for (const k of Object.keys(this.git)) if (!keys.has(k)) {
      delete this.git[k];
      delete this.checked[k];
      this.unsure.delete(k);
    }
    const repos = new Set(Object.values(this.git).filter(Boolean).map((g) => g.repo));
    for (const [repo, pending] of this.watching) if (!repos.has(JSON.stringify([null, repo]))) {
      this.watching.delete(repo);
      pending.cancel();
    }
    const due = new Set([...keys].filter((k) => !(k in this.git)));
    for (const [id, k] of Object.entries(at)) if (this.at[id] && this.at[id] !== k && keys.has(k)) due.add(k);
    this.at = at;
    const spaceOf = {};
    for (const s of sp) for (const t of s.tabs ?? []) spaceOf[t.id] = s;
    const busy = {};
    for (const p of ps) {
      if (!p.terminal || !spaceOf[p.tab]) continue;
      busy[p.pane] = p.status === "working" || !(p.program?.shell || p.program?.agent);
      if (this.busy[p.pane] && !busy[p.pane]) this.sameRepo(at[spaceOf[p.tab].id], keys).forEach((k) => due.add(k));
    }
    this.busy = busy;
    for (const m of machines()) {
      const ready = m.layout === "ready";
      if (ready && this.ready[m.name] === false) for (const k of keys) if (JSON.parse(k)[0] === m.name) due.add(k);
      this.ready[m.name] = ready;
    }
    if (window().active) {
      for (const k of keys) {
        const asks = this.git[k] || this.unsure.has(k);
        if (asks && !this.folded.has(JSON.parse(k)[0]) && now - (this.checked[k] ?? 0) > FALLBACK) due.add(k);
      }
    }
    return due;
  }

  // `key` and the other places in its repo (a commit there moves their ahead/behind).
  sameRepo(key, keys) {
    const repo = this.git[key]?.repo;
    return [key, ...(repo ? [...keys].filter((k) => this.git[k]?.repo === repo) : [])];
  }

  refreshMachines(cx) {
    cx.spawn(async cx => {
      try { const r = await hc(["machine", "ls", "--json"]); if (r.code === 0) this.machines = (JSON.parse(r.stdout).machines ?? []).filter((m) => !m.temporary); } catch {}
      cx.notify();
    });
  }

  rebuilt(machine) {
    return machine?.state === "unreachable" && /^a different core answers there \("[^"]+"\)$/.test(machine.why ?? "");
  }

  reconnect(machine, cx) {
    const name = machine.name;
    if (this.reconnecting[name]?.busy) return;
    const state = this.reconnecting[name] ??= { machine, removed: false };
    state.busy = true;
    state.error = null;
    localStorage.setItem("machines.reconnecting", JSON.stringify(this.reconnecting));
    cx.notify();
    cx.spawn(async cx => {
      try {
        const ask = async args => {
          const r = await hc([...args, "--json"]);
          if (r.code !== 0) {
            let error;
            try { error = JSON.parse(r.stdout || r.stderr).error?.message; } catch {}
            throw new Error(error || r.stderr || r.stdout || "Couldn't connect.");
          }
        };
        if (!state.removed) {
          await ask(["machine", "rm", name]);
          state.removed = true;
          localStorage.setItem("machines.reconnecting", JSON.stringify(this.reconnecting));
        }
        const args = ["machine", "add"];
        if (machine.via) args.push("--via", machine.target);
        else args.push(machine.target);
        args.push("--name", name);
        if (machine.session) args.push("--session", machine.session);
        if (machine.temporary) args.push("--temp");
        await ask(args);
        this.folded.delete(name);
        localStorage.setItem("machines.folded", JSON.stringify([...this.folded]));
        delete this.reconnecting[name];
      } catch (e) {
        state.error = String(e.message ?? e);
        state.busy = false;
      }
      localStorage.setItem("machines.reconnecting", JSON.stringify(this.reconnecting));
      this.refreshMachines(cx);
      cx.notify();
    });
  }

  // One look at a time, each place once however often it was asked for meanwhile.
  refreshGit(keys, cx) {
    for (const k of keys) this.pending.add(k);
    if (this.refreshing) return;
    this.refreshing = true;
    cx.spawn(async (cx) => {
      while (this.pending.size) {
        const keys = [...this.pending];
        this.pending.clear();
        let next = 0;
        await Promise.all(Array.from({ length: Math.min(AT_ONCE, keys.length) }, async () => {
          while (next < keys.length) await this.check(keys[next++], cx);
        }));
      }
      this.refreshing = false;
      cx.notify();
    });
  }

  // One place's git: branch, ahead/behind, its repo.
  async check(key, cx) {
    const [on, cwd] = JSON.parse(key);
    this.checked[key] = Date.now();
    this.unsure.delete(key);
    try {
      // Ref-only reads avoid scanning the worktree or waking its index watch.
      // Two reads: a folder name may itself contain a newline.
      const [r, common] = await both(
        exec("git", ["rev-parse", "--path-format=absolute", "--show-toplevel"], { cwd, on }),
        exec("git", ["rev-parse", "--path-format=absolute", "--git-common-dir"], { cwd, on }),
      );
      if (r.code !== 0 || common.code !== 0) {
        // Only git's own "no" is remembered as no repo; anything else is asked again.
        if (!/not a git repository/i.test(r.code !== 0 ? r.stderr : common.stderr)) {
          this.unsure.add(key);
          this.git[key] ??= null;
        } else this.git[key] = null;
        return;
      }
      // The repo's own .git folder names it; a worktree's top differs from it.
      const top = r.stdout.replace(/\n$/, ""), repo = common.stdout.replace(/\n$/, "");
      const [branch, counts] = await both(
        exec("git", ["symbolic-ref", "-q", "HEAD"], { cwd, on }),
        exec("git", ["rev-list", "--left-right", "--count", "HEAD...@{upstream}"], { cwd, on }),
      );
      const name = repo.endsWith("/.git") ? base(repo.slice(0, -5)) : base(repo).replace(/\.git$/, "");
      const [ahead, behind] = counts.code === 0 ? counts.stdout.trim().split(/\s+/).map(Number) : [0, 0];
      const info = { name, branch: branch.code === 0 ? branch.stdout.trim().replace(/^refs\/heads\//, "") : "(detached)", ahead, behind, repo: JSON.stringify([on, repo]), linked: repo !== `${top}/.git` };
      this.git[key] = info;
      if (!on) this.watch(repo, cx);
    } catch {
      // Couldn't ask (the machine is away): keep what it showed, look again later.
      this.git[key] ??= null;
      this.unsure.add(key);
    }
  }

  watch(repo, cx) {
    if (this.watching.has(repo)) return;
    const pending = watchFolder(repo);
    this.watching.set(repo, pending);
    cx.spawn(async (cx) => {
      let current = pending;
      try {
        for (;;) {
          await current;
          if (this.watching.get(repo) !== current) return;
          const mine = JSON.stringify([null, repo]);
          const keys = Object.keys(this.git).filter((k) => this.git[k]?.repo === mine);
          if (!keys.length) break;
          this.refreshGit(keys, cx);
          current = watchFolder(repo);
          this.watching.set(repo, current);
        }
      } catch {}
      if (this.watching.get(repo) === current) this.watching.delete(repo);
    });
  }

  menu(w) {
    // A popup is as tall as its items; height is only the most.
    openOverlay({ mod: "pbogut-spaces", kind: "popup", width: 240, height: 300,
      props: { spaceMenu: { id: w.id, folderKey: this.folderKey(w) } } });
  }

  orderingDue(now) {
    return this.ordering && now - this.ordering.at >= 1000
      && this.ordering.machines.every(name => machines().some(m => m.name === name && m.layout === "ready"));
  }

  // Spaces in folder order, each worktree space under its main checkout's.
  // Updating core order also makes numbered and next/previous shortcuts agree.
  ordered() {
    const sp = spaces(), ps = panes();
    const ready = (w) => this.shown.has(w.id) || where(w, ps) in this.git || Date.now() - (this.born[w.id] ??= Date.now()) > 1500;
    for (const w of sp) if (!this.shown.has(w.id) && ready(w)) this.shown.add(w.id);
    const list = sp.map((w, i) => ({ w, i, g: this.git[where(w, ps)] ?? null }));
    const mains = new Set(list.filter((r) => r.g && !r.g.linked).map((r) => r.g.repo));
    const nested = (r) => r.g?.linked && mains.has(r.g.repo);
    let out = [];
    const placed = new Set(); // repos whose worktrees are listed (under the first of its spaces)
    for (const r of list) {
      if (nested(r)) continue;
      out.push({ ...r, tree: null });
      if (!r.g || r.g.linked || placed.has(r.g.repo)) continue;
      placed.add(r.g.repo);
      const kids = list.filter((k) => nested(k) && k.g.repo === r.g.repo);
      kids.forEach((k, n) => out.push({ ...k, tree: n === kids.length - 1 ? "└─" : "├─" }));
    }
    out = orderFolders(out, this.folderConfig, space => this.folderFor(space));
    // Simulate the batch so later indexes include earlier moves. An attempted
    // write can lose a sync conflict: allow the echo to settle before retrying.
    const order = sp.map(w => w.id);
    const target = out.map(r => r.w.id);
    const key = JSON.stringify([order, target, machines()]);
    if (order.every((id, i) => id === target[i])) {
      this.ordering = null;
    } else if (this.ordering?.key !== key || this.orderingDue(Date.now())) {
      const moved = new Set();
      this.ordering = { key, at: Date.now(), machines: [] };
      for (let i = 0; i < out.length; i++) {
        const from = order.indexOf(out[i].w.id);
        if (from === i) continue;
        run("space.move", { id: out[i].w.id, index: i + 1 });
        moved.add(out[i].w.machine ?? null);
        order.splice(i, 0, order.splice(from, 1)[0]);
      }
      this.ordering.machines = [...moved];
    }
    return out.map((r, i) => ({ ...r, i })).filter(r => this.shown.has(r.w.id));
  }

  // Reveal a switched-to space even when its machine or folder was folded.
  // Folding the current group by hand remains possible until selection changes.
  revealFolder(rows) {
    const active = rows.find(row => row.w.active)?.w;
    const folder = active && JSON.stringify([active.machine ?? null, this.folderFor(active)]);
    const key = active && JSON.stringify([active.id, folder]);
    if (key === this.folderSelection) return;
    this.folderSelection = key;
    if (!active) return;
    if (this.foldersFolded.delete(folder)) localStorage.setItem("pbogut.folders.folded", JSON.stringify([...this.foldersFolded]));
    if (this.folded.delete(active.machine ?? null)) localStorage.setItem("machines.folded", JSON.stringify([...this.folded]));
  }

  foldered(rows, machine, t, collapsed, draw) {
    const items = [];
    let activeAt = -1;
    for (const folder of folderNames(this.folderConfig)) {
      const mine = rows.filter(row => this.folderFor(row.w) === folder);
      if (!mine.length && !this.showEmptyFolders) continue;
      const id = JSON.stringify([machine, folder]);
      const folded = this.foldersFolded.has(id);
      const target = this.pressed !== null && this.overFolder === id;
      const header = h_flex().id(`folder-${id}`).h(24).flex_none().mt(4)
        .px(collapsed ? 0 : 8).gap(7).items_center().rounded(6)
        .text_size(11).font_semibold().text_color(t.muted)
        .cursor_pointer()
        .when(target, el => el.bg(t.selected).border(1).border_color(t.accent))
        .when(!target, el => el.hover(s => s.bg(t.hover)))
        .tooltip(`${folder} (${mine.length})`)
        .when(collapsed, el => el.w(RAIL_CELL).justify_center())
        .on_mouse_move((_event, cx) => {
          const source = spaces().find(s => s.id === this.pressed);
          const over = source && (source.machine ?? null) === machine ? id : null;
          if (this.pressed !== null && (this.overFolder !== over || this.over !== null)) {
            this.overFolder = over;
            this.over = null;
            cx.notify();
          }
        })
        .on_mouse_up("left", (_event, cx) => {
          cx.stop_propagation();
          const from = this.pressed;
          const source = spaces().find(s => s.id === from);
          this.pressed = null;
          this.over = null;
          this.overFolder = null;
          if (from !== null) {
            if (source && (source.machine ?? null) === machine) this.assignFolder(source, folder, cx);
          } else {
            folded ? this.foldersFolded.delete(id) : this.foldersFolded.add(id);
            localStorage.setItem("pbogut.folders.folded", JSON.stringify([...this.foldersFolded]));
          }
          cx.notify();
        })
        .child(svg("mods/workspace-chrome/folder.svg").size(12).flex_none())
        .when(!collapsed, el => el
          .child(div().flex_1().truncate().child(folder))
          .child(div().flex_none().text_color(t.dim).font_normal().child(String(mine.length)))
          .child(svg(`mods/workspace-chrome/chevron-${folded ? "right" : "down"}.svg`).size(11).flex_none()));
      items.push(collapsed ? railCell(header) : header);
      if (!folded) {
        const selected = mine.findIndex(row => this.isSelected(row.w));
        if (selected !== -1) activeAt = items.length + selected;
        items.push(...mine.map(draw));
      }
    }
    return { items, activeAt };
  }

  // The rows, under machine headers, then folder headers.
  grouped(t, collapsed) {
    const rows = this.ordered();
    this.publishRows(rows, t);
    this.revealFolder(rows);
    this.hintTargets = [];
    const draw = (r) => {
      this.hintTargets.push(r.w.id);
      return collapsed ? this.compact(r, t) : this.row(r, t);
    };
    // Where the active space's row lands among the children this returns: the list scrolls by its direct
    // children, and machine headers, login notes and loading rows count too.
    this.activeAt = -1;
    let before = 0;
    const remote = [...new Set([...rows.map(r => r.w.machine).filter(Boolean), ...this.machines.map(m => m.name), ...Object.keys(this.reconnecting)])].sort();
    const loading = m => {
      const layout = machines().find(k => k.name === m)?.layout;
      return layout === "loading" || (!layout && this.machines.some(k => k.name === m && k.state === "connected"))
        || spaces().some(s => (s.machine ?? null) === m && !this.shown.has(s.id));
    };
    const loadingRow = m => h_flex().id(`machine-loading-${m ?? "local"}`).h(28).flex_none().px(collapsed ? 0 : 8).items_center().when(collapsed, el => el.justify_center()).text_size(12).text_color(t.dim).child(collapsed ? "…" : "Loading…");
    if (!remote.length) {
      if (loading(null) && !rows.length) return [loadingRow(null)];
      const group = this.foldered(rows, null, t, collapsed, draw);
      this.activeAt = group.activeAt;
      return group.items;
    }
    const machineNames = [null, ...remote];
    return machineNames.flatMap((m) => {
      const mine = rows.filter((r) => (r.w.machine ?? null) === m);
      const repair = this.reconnecting[m];
      const machine = this.machines.find(k => k.name === m) ?? repair?.machine;
      const connected = !m || machine?.state === "connected";
      const rebuilt = this.rebuilt(machine) || !!repair;
      const login = machine?.state === "needs_login" ? `hc machine login ${m}` : null;
      const folded = this.folded.has(m);
      const icon = svg(`mods/workspace-chrome/${m ? "server" : "monitor"}.svg`).size(13).flex_none();
      const badge = div().absolute().right(-3).bottom(-2).size(6).rounded(3).border_1().border_color(t.chrome).bg(connected ? t.ansi2 : t.dim);
      const head = h_flex().id(`machine-${m ?? "local"}`).h(26).flex_none().px(collapsed ? 0 : 8).gap(7).items_center().text_size(11).text_color(t.dim)
        .when(collapsed, el => el.mt(4).w(RAIL_CELL).justify_center().rounded(6).tooltip(login ? `${m} needs a login: run ${login}. Click for Copy.` : m ? `${m} · ${connected ? "connected" : (machine?.state ?? "asleep").replace(/_/g, " ")}` : "This computer"))
        .cursor_pointer().hover(s => s.bg(t.hover))
        .on_click((_e, cx) => {
          if (collapsed && login) { run("app.settings", { section: "machines" }); return; }
          folded ? this.folded.delete(m) : this.folded.add(m);
          localStorage.setItem("machines.folded", JSON.stringify([...this.folded]));
          cx.notify();
        })
        .when(machine?.keeps_running_after_logout === false, el => el.child(div().id(`machine-logout-${m}`)
          .flex_none().text_color(t.blocked).tooltip("Agents stop when you disconnect. Click for the fix.")
          .on_click((_e, cx) => { cx.stop_propagation(); openOverlay({ mod: "machine-add", kind: "dialog", width: 560 }); }).child("⚠")))
        .when(!collapsed, el => el.child(icon))
        .when(collapsed, el => el.child(div().relative().flex_none().child(icon).when(Boolean(m), el => el.child(badge))))
        .when(!collapsed, el => el.child(div().flex_1().truncate().child(m ?? "This computer"))
          .when(!connected && !rebuilt && !login, el => el.child(div().flex_none().child((machine?.state ?? "asleep").replace(/_/g, " "))))
          .when(rebuilt, el => el.child(h_flex().flex_none().gap(3).items_center()
            .child(div().max_w(140).truncate().child(repair?.error || "rebuilt ·"))
            .child(div().id(`machine-connect-${m}`).text_color(repair?.error ? t.blocked : t.muted)
              .hover(s => s.text_color(t.foreground))
              .tooltip(repair?.error || "This machine was rebuilt or replaced. Click to connect to the new one.")
              .on_click((_e, cx) => { cx.stop_propagation(); this.reconnect(machine, cx); })
              .child(repair?.busy ? "Connecting…" : "Connect"))))
          .when(connected, el => el.child(div().id(`machine-add-${m ?? "local"}`).flex_none().px(4).rounded(4).hover(s => s.bg(t.hover).text_color(t.foreground))
            .on_click((_e, cx) => { cx.stop_propagation(); run("space.new", { machine: m ?? "" }); }).child("+")))
          .child(div().size(6).rounded(3).flex_none().bg(connected ? t.ansi2 : t.dim))
          .child(svg(`mods/workspace-chrome/chevron-${folded ? "right" : "down"}.svg`).size(11).flex_none()));
      const empty = h_flex().id(`machine-new-${m ?? "local"}`).h(28).flex_none().px(collapsed ? 0 : 8).gap(7).items_center().rounded(7)
        .text_size(12).text_color(t.dim).hover(s => s.bg(t.hover).text_color(t.foreground))
        .on_click(() => run("space.new", { machine: m ?? "" }))
        .when(collapsed, el => el.w(RAIL_CELL).rounded(6).justify_center().tooltip(`New space on ${m ?? "this computer"}`)
          .child(h_flex().size(18).rounded(5).border_1().border_color(t.dim).items_center().justify_center()
            .child(svg("mods/workspace-chrome/plus.svg").size(10))))
        .when(!collapsed, el => el.child(svg("mods/workspace-chrome/plus.svg").size(12)).child("New space there"));
      if (!collapsed && rebuilt) { before += 1; return [head]; }
      const cell = collapsed ? railCell : (el) => el;
      const guidance = !collapsed && login ? [v_flex().px(8).pb(6).gap(3).flex_none()
        .child(div().text_size(11).text_color(t.blocked).child("needs a login: run"))
        .child(h_flex().gap(5).items_center()
          .child(div().flex_1().min_w(0).truncate().tooltip(login).text_size(11).text_color(t.muted).child(login))
          .child(div().id(`machine-login-copy-${m}`).flex_none().px(5).py(2).rounded(4)
            .text_size(11).text_color(t.foreground).bg(t.raised).cursor_pointer().hover(s => s.bg(t.hover))
            .on_click((_e, cx) => { cx.stop_propagation(); cx.write_to_clipboard(login); this.copiedLogin = login; cx.notify(); })
            .child(this.copiedLogin === login ? "Copied" : "Copy")))] : [];
      const group = folded ? { items: [], activeAt: -1 } : this.foldered(mine, m, t, collapsed, draw);
      const items = [cell(head), ...guidance, ...group.items,
        ...(!folded && !mine.length ? [loading(m) ? loadingRow(m) : cell(empty)] : [])];
      if (group.activeAt >= 0) this.activeAt = before + 1 + guidance.length + group.activeAt;
      before += items.length;
      return items;
    });
  }

  name(w) {
    return isProject(w) ? this.projects.get(projectKey(w))?.name ?? projectName("", w.folder, w.name) : w.name;
  }

  icon(w, tree, t) {
    if (tree) return { svg: "mods/workspace-chrome/branch.svg" };
    const color = (shared("space.colors") ?? {})[w.id] ?? "ansi6";
    return {
      initial: [...this.name(w)][0]?.toUpperCase() ?? "?",
      color: color.startsWith("#") ? color : (MARK[color] ?? t[color]),
    };
  }

  // Give the picker and agents the sidebar's resolved order and labels, before folding.
  publishRows(rows, t) {
    const folders = { names: folderNames(this.folderConfig), fallback: this.folderConfig.fallback };
    if (JSON.stringify(shared("pbogut.spaces.folders")) !== JSON.stringify(folders)) {
      setShared("pbogut.spaces.folders", folders);
    }
    const remote = [...new Set(rows.map(r => r.w.machine).filter(Boolean))].sort();
    const snapshot = [null, ...remote].flatMap(machine =>
      rows.filter(r => (r.w.machine ?? null) === machine).map(({ w, g, tree }) => ({
        id: w.id, name: this.name(w), folder: this.folderFor(w), tree, icon: this.icon(w, tree, t),
        branch: g?.branch ?? "", ahead: g?.ahead ?? 0, behind: g?.behind ?? 0,
      })));
    if (JSON.stringify(shared("pbogut.spaces.rows")) !== JSON.stringify(snapshot)) {
      setShared("pbogut.spaces.rows", snapshot);
    }
  }

  // The full Git branch remains available on hover; only its display is shortened.
  gitTail(g, t) {
    const raw = g.branch ?? "(detached)";
    const branch = raw.replace(/^\d{4}-\d{2}-\d{2}-(?=.)/, "");
    return h_flex()
      .flex_auto()
      .min_w(SIDE_MIN)
      .gap(5)
      .justify_end()
      .items_center()
      .text_size(11.5)
      .text_color(t.accent)
      .child(div().min_w(0).truncate().tooltip(raw).child(branch))
      .when(g.ahead > 0, (el) => el.child(div().flex_none().text_color(t.ansi2).child(`\u2191${g.ahead}`)))
      .when(g.behind > 0, (el) => el.child(div().flex_none().text_color(t.ansi1).child(`\u2193${g.behind}`)));
  }

  isSelected(w) {
    return this.hintState ? this.hintState.selected === w.id : w.active;
  }

  row({ w, i, g, tree }, t) {
    const on = this.isSelected(w);
    const name = this.name(w);
    const icon = this.icon(w, tree, t);
    const fromIndex = this.pressed === null ? -1 : spaces().findIndex(s => s.id === this.pressed);
    return v_flex()
      .relative()
      .id(`space-${w.id}`)
      .px(8)
      .h(rowHeight({ tree }))
      .flex_none()
      .justify_center()
      .rounded(8)
      .when(on, (el) => el.bg(t.selected))
      .when(!on, (el) => el.hover((s) => s.bg(t.hover)))
      .when(this.pressed === w.id && this.over !== w.id, (el) => el.opacity(0.5))
      .when(this.pressed !== null && this.over === w.id && this.pressed !== w.id, (el) => el.child(
        div().absolute().left(0).right(0).h(2).bg(t.accent)
          .when(fromIndex < i, line => line.bottom(0))
          .when(fromIndex > i, line => line.top(0)),
      ))
      .on_mouse_down("left", () => {
        this.pressed = w.id;
        this.over = w.id;
        this.overFolder = null;
      })
      .on_mouse_move((_e, cx) => {
        const source = spaces().find(s => s.id === this.pressed);
        const over = source && (source.machine ?? null) === (w.machine ?? null)
          && this.folderFor(source) === this.folderFor(w) ? w.id : null;
        if (this.pressed !== null && (this.over !== over || this.overFolder !== null)) {
          this.over = over;
          this.overFolder = null;
          cx.notify();
        }
      })
      .on_mouse_up("left", (_e, cx) => {
        const from = this.pressed;
        const over = this.over;
        this.pressed = null;
        this.over = null;
        this.overFolder = null;
        if (from !== null && over === w.id && from !== w.id) {
          const index = spaces().findIndex(s => s.id === w.id);
          if (index !== -1) run("space.move", { id: from, index: index + 1 });
        } else if (from === w.id) run("space.select", { id: w.id });
        cx.notify();
      })
      .on_mouse_down("right", () => this.menu(w))
      .child(
        h_flex()
          .gap(9)
          .items_center()
          .when(Boolean(tree), el => el.pl(22).child(svg(icon.svg).size(13).flex_none().text_color(t.dim)))
          .when(!tree, el => el.child(h_flex().size(18).flex_none().rounded(5).bg(icon.color).items_center().justify_center().text_size(10.5).font_bold().text_color("#ffffff")
            .child(icon.initial)))
          .child(div().flex_initial().min_w(SIDE_MIN).truncate().tooltip(w.folder || w.name).text_color(t.foreground).child(name))
          .child(g ? this.gitTail(g, t) : div().flex_1()),
      ).when(Boolean(this.hintState?.hints[w.id]), el => el.child(this.hintBadge(w.id, tree ? 30 : 8, t)));
  }

  hintBadge(id, left, t) {
    const { hints, prefix } = this.hintState;
    const color = hints[id].startsWith(prefix) ? t.accent : t.dim;
    return h_flex().absolute().left(left).top(4).h(18).min_w(18).px(2).rounded(4).bg(t.surface)
      .border_1().border_color(color).items_center().justify_center().font_family("JetBrainsMono Nerd Font Mono")
      .text_size(12).font_bold().text_color(color).whitespace_nowrap().child(hints[id].toUpperCase());
  }

  compact({ w, i }, t) {
    return railCell(h_flex()
      .id(`space-${w.id}`)
      .relative()
      .w(RAIL_CELL)
      .h(26)
      .rounded(6)
      .justify_center()
      .items_center()
      .when(this.isSelected(w), (el) => el.bg(t.selected))
      .when(!this.isSelected(w), (el) => el.hover((s) => s.bg(t.hover)))
      .on_click(() => run("space.select", { id: w.id }))
      .child(div().text_color(w.active ? t.foreground : t.muted).child(String(i + 1)))
      .child(div().absolute().right(5).text_color(tone(t, w.status)).child(glyph(w.status)))
      .when(Boolean(this.hintState?.hints[w.id]), el => el.child(this.hintBadge(w.id, 4, t))));
  }

  render(cx) {
    if (this.popup) return this.popup.render(cx);
    const t = theme();
    const collapsed = narrow();
    const palette = ["ansi6", "ansi3", "ansi4", "ansi5", "ansi2", "ansi1"];
    const sp = spaces();
    this.refreshProjects(sp, cx);
    const ids = new Set(sp.map(p => p.id));
    const kept = Object.fromEntries(Object.entries(shared("space.colors") ?? {}).filter(([id]) => ids.has(id)));
    let changed = Object.keys(kept).length !== Object.keys(shared("space.colors") ?? {}).length;
    for (const p of sp) {
      if (kept[p.id] || p.name === "~") continue;
      const uses = c => Object.values(kept).filter(v => v === c).length;
      kept[p.id] = palette.reduce((best, c) => uses(c) < uses(best) ? c : best);
      changed = true;
    }
    if (changed) setShared("space.colors", kept);
    const hints = shared("pbogut.sidebar.hints");
    this.hintState = hints?.mode === "spaces" ? hints : null;
    const list = this.grouped(t, collapsed);
    if (JSON.stringify(this.hintTargets) !== JSON.stringify(shared("pbogut.spaces.hintTargets"))) {
      setShared("pbogut.spaces.hintTargets", this.hintTargets);
    }
    // Bring the active space into view when it, or its place in the list, changes; a row already in view stays put.
    const active = sp.find(p => this.isSelected(p))?.id;
    if (active !== this.revealed || this.activeAt !== this.revealedAt) {
      this.revealed = active;
      this.revealedAt = this.activeAt;
      if (this.activeAt >= 0) this.scroll.scroll_to_item(this.activeAt);
    }
    return v_flex().size_full().min_h(0).bg(t.chrome).text_size(13)
      .child(h_flex().h(31).pl(16).pr(10).items_center().justify_between().text_size(11.5).text_color(t.dim)
        .when(collapsed, el => el.pl(0).pr(0).justify_center())
        .when(!collapsed, el => el.child("Spaces"))
        .when(!collapsed && Boolean(this.folderError), el => el.child(div().px(4).text_color(t.blocked).tooltip(this.folderError).child("!")))
        .when(!collapsed, el => el.child(h_flex().flex_1().justify_end()
          .child(div().id("space-empty-folders").size(26).flex_none().flex().items_center().justify_center().rounded(6)
            .text_color(this.showEmptyFolders ? t.foreground : t.dim)
            .hover(s => s.bg(t.hover).text_color(t.foreground))
            .tooltip(this.showEmptyFolders ? "Hide empty folders" : "Show empty folders")
            .on_click((_event, cx) => {
              this.showEmptyFolders = !this.showEmptyFolders;
              localStorage.setItem("pbogut.folders.show-empty", JSON.stringify(this.showEmptyFolders));
              cx.notify();
            })
            .child(svg("mods/workspace-chrome/folder.svg").size(14)))))
        .child(div().id("space-new").size(26).flex_none().flex().items_center().justify_center().rounded(6).hover(s => s.bg(t.hover).text_color(t.foreground))
          .on_click(() => run("space.new")).child(svg("mods/workspace-chrome/plus.svg").size(14))))
      .child(v_flex().flex_1().min_h(0).px(collapsed ? 0 : 8).pb(14).overflow_y_scrollbar().mode("always").track_scroll(this.scroll)
        // A block above (another mod's) growing, or the window resizing, shrinks this list and can push the active space out.
        .on_size_change((_size, cx) => { if (this.activeAt >= 0) { this.scroll.scroll_to_item(this.activeAt); cx.notify(); } })
        .on_mouse_up("left", (_e, cx) => { this.pressed = null; this.over = null; this.overFolder = null; cx.notify(); })
        .children(list));
  }
}
