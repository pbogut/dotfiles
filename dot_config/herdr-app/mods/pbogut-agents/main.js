// Based on Herdr App 0.1.16's agents mod, licensed under Apache-2.0.
// https://github.com/herdrdev/herdr-app/blob/v0.1.16/defaults/mods/agents/main.js
// Agents in grouped or priority views; parents take their most urgent sub-agent's place.
// Uses Spaces' project labels and branches, and adds a Folder + priority view.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { agents, terminals, focused, spaces, run, theme, shared, setShared, setAgentOrder, openOverlay, closeOverlay, props, window, layout, checking, nextCommand } from "herdr";
import { icon, status } from "./appearance.js";
import AgentPicker, { openPicker } from "./picker.js";

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

// To the rail (on macOS wide enough for the traffic lights), or back to the width it had.
function toggleSidebar() {
  const width = find(layout(), "sidebar")?.size?.px;
  if (!narrow()) setShared("sidebar.width", width);
  // Mods edited before the rail went by width still read the flag.
  setShared("sidebar.collapsed", !narrow());
  run("layout.resize", { id: "sidebar", px: narrow() ? (shared("sidebar.width") ?? 268) : window()?.platform === "macos" ? 76 : 44 });
}

const RANK = { blocked: 4, done: 3, working: 2, idle: 1 };
// A sub-agent without a pane isn't in agents(): its raw word, error counting as
// blocked. It's never done: it reports to its parent, and the parent's done is the news.
const kidStatus = (k, listed) => {
  const s = listed.get(k.address) ?? k.status;
  return s === "error" ? "blocked" : s === "done" ? "idle" : s;
};
const SORTS = [
  { id: "priority", label: "Priority", icon: "clock" },
  { id: "grouped", label: "Grouped by space", icon: "layers" },
  { id: "folder-priority", label: "Folder + priority", icon: "folder" },
];
const sortOf = () => SORTS.find((s) => s.id === shared("agents.sort")) ?? SORTS[0];
const SECTION = { 4: "Needs you", 3: "Done", 2: "Working", 1: "Idle" };
const SECTION_STATUS = { 4: "blocked", 3: "done", 2: "working" };

function duration(ms) {
  const m = Math.floor(ms / 60000);
  if (m < 1) return "<1m";
  if (m < 60) return `${m}m`;
  const h = Math.floor(m / 60);
  return h < 24 ? `${h}h` : `${Math.floor(h / 24)}d`;
}

export default class Agents extends View {
  init(_props, cx) {
    if (props()?.picker) {
      this.picker = new AgentPicker(props(), cx);
      return;
    }
    if (props()?.sortMenu) return;
    this.folded = new Set();
    // Each agent's last state and when it changed (ms), kept across restarts.
    try { this.changed = JSON.parse(localStorage.getItem("changed") ?? "{}"); } catch { this.changed = {}; }
    if (!this.changed || typeof this.changed !== "object" || Array.isArray(this.changed)) this.changed = {};
    try { this.pendingPins = JSON.parse(localStorage.getItem("pins") ?? "[]"); } catch { this.pendingPins = []; }
    if (!Array.isArray(this.pendingPins)) this.pendingPins = [];
    if (!this.pendingPins.length) localStorage.removeItem("pins");
    this.migratingPins = new Set();
    cx.timer.every(30000, (cx) => cx.notify());
    if (!checking()) cx.spawn(async () => {
      for (;;) if (await nextCommand() === "picker") openPicker();
    });
  }

  // Stamps agents whose state changed. Done and idle count as one: looking at a
  // finished agent turns done into idle, and looking isn't the agent doing anything.
  track(list, now) {
    let dirty = false;
    for (const a of list) {
      const s = a.status === "done" ? "idle" : a.status;
      if (this.changed[a.address]?.s === s) continue;
      this.changed[a.address] = { s, at: now };
      dirty = true;
    }
    if (!dirty) return;
    // Gone and old: the list alone is empty right after a start.
    const listed = new Set(list.map((a) => a.address));
    for (const [k, c] of Object.entries(this.changed)) if (!listed.has(k) && now - c.at > 30 * 86400000) delete this.changed[k];
    localStorage.setItem("changed", JSON.stringify(this.changed));
  }

  // Keep offline pins until their terminal returns, and keep each pending until
  // core echoes the label so a failed write doesn't erase the old pin.
  migratePins(all) {
    const listed = new Map(all.filter((t) => t.state === "live").map((t) => [t.address, t]));
    const pending = this.pendingPins.filter((address) => {
      const terminal = listed.get(address);
      if (!terminal) return true;
      if (terminal.labels?.["herdr.pinned"]) return false;
      if (!this.migratingPins.has(address)) {
        this.migratingPins.add(address);
        run("terminal.pin", { terminal: address, pinned: true });
      }
      return true;
    });
    if (pending.length === this.pendingPins.length) return;
    this.pendingPins = pending;
    if (pending.length) localStorage.setItem("pins", JSON.stringify(pending));
    else localStorage.removeItem("pins");
  }

  since(a) {
    return this.changed[a.address]?.at ?? 0;
  }

  rank(a) {
    return RANK[a.status] ?? 0;
  }

  sortMenu(t) {
    const on = sortOf().id;
    return v_flex()
      .w_full()
      .p(5)
      .bg(t.popover)
      .text_size(12.8)
      .child(div().px(8).pt(4).pb(6).text_size(11).text_color(t.dim).child("Sort agents"))
      .children(SORTS.map((s) => h_flex()
        .id(`sort-${s.id}`)
        .h(31)
        .px(8)
        .gap(9)
        .rounded(7)
        .items_center()
        .text_color(t.foreground)
        .hover((el) => el.bg(t.hover))
        .on_click(() => {
          setShared("agents.sort", s.id);
          closeOverlay(props().overlay);
        })
        .child(svg(`mods/workspace-chrome/${s.icon}.svg`).size(14).flex_none().text_color(t.muted))
        .child(div().flex_1().child(s.label))
        .when(s.id === on, (el) => el.child(svg("mods/workspace-chrome/check.svg").size(14).flex_none().text_color(t.foreground)))));
  }

  peek(addr) {
    run("terminal.peek", { terminal: addr });
  }

  // Live sub-agents of `addr`, depth first, each with the tree lines in front of it.
  tree(all, addr, lead = []) {
    const kids = all.filter((k) => k.parent === addr && k.state === "live");
    return kids.flatMap((k, i) => {
      const last = i === kids.length - 1;
      return [
        { t: k, lines: [...lead, last ? "└" : "├"] },
        ...this.tree(all, k.address, [...lead, last ? "" : "│"]),
      ];
    });
  }

  subRow(t, s, shown, compact) {
    const k = s.t;
    const st = kidStatus(k, this.listed);
    const pic = icon(k.program, 14, t.foreground);
    const on = k.address === shown;
    return h_flex().relative()
      .id(`sub-${k.address}`)
      .pl(39)
      .pr(8)
      .rounded(8)
      .h(26)
      .flex_none()
      .gap(0)
      .items_center()
      .text_size(12.5)
      .when(on, (el) => el.bg(t.raised))
      .hover((s) => s.bg(t.hover))
      .on_click(() => (this.listed.has(k.address) ? run("pane.focus", { terminal: k.address }) : this.peek(k.address)))
      .children(s.lines.map(l => div().self_start().mt(-4).w(9).h(17).mr(4).flex_none()
        .when(Boolean(l), el => el.border_l(1.5).border_color(t.input))
        .when(l === "└" || l === "├", el => el.border_b(1.5).rounded_bl(6))))
      .when(Boolean(pic), el => el.child(div().mr(8).child(pic)))
      .child(div().flex_1().truncate().text_color(on ? t.foreground : t.muted).child(k.name || k.template || k.program?.name || k.address))
      .child(status(t, { status: st }, compact))
      .when(Boolean(this.hintState?.hints[k.address]), el => el.child(this.hintBadge(k.address, 39 + 13 * s.lines.length, t)));
  }

  hintBadge(address, left, t) {
    const { hints, prefix } = this.hintState;
    const color = hints[address].startsWith(prefix) ? t.accent : t.dim;
    return h_flex().absolute().left(left).top(4).h(18).min_w(18).px(2).rounded(4).bg(t.surface)
      .border_1().border_color(color).items_center().justify_center().font_family("JetBrainsMono Nerd Font Mono")
      .text_size(12).font_bold().text_color(color).whitespace_nowrap().child(hints[address].toUpperCase());
  }

  render(cx) {
    if (this.picker) return this.picker.render();
    const t = theme();
    if (props()?.sortMenu) return this.sortMenu(t);
    const collapsed = narrow();
    const sort = sortOf();
    let list = agents();
    this.listed = new Map(list.map((a) => [a.address, a.status]));
    const all = terminals();
    this.migratePins(all);
    const shown = focused()?.agent;
    const now = Date.now();
    this.track(list, now);
    // A kept sub-agent (one with a pane) is in agents() too: where a tree shows
    // it, it gets no row of its own, unless it's pinned.
    const nested = new Set(collapsed ? [] : list.flatMap((a) => this.tree(all, a.address).map((s) => s.t.address)));
    list = list.filter((a) => a.pinned || !nested.has(a.address));
    const byFolder = sort.id === "folder-priority";
    const byPriority = sort.id === "priority" || byFolder;
    const sp = spaces();
    const liveSpaces = new Set(sp.map(s => s.id));
    const spaceRows = new Map((shared("pbogut.spaces.rows") ?? [])
      .filter(row => liveSpaces.has(row.id)).map(row => [row.id, row]));
    const nameOf = a => spaceRows.get(a.space)?.name || a.space_name || "";
    const branchOf = a => spaceRows.get(a.space)?.branch || "";
    const folders = shared("pbogut.spaces.folders") ?? { names: [], fallback: "other" };
    const folderOf = a => spaceRows.get(a.space)?.folder ?? folders.fallback;
    const urgency = new Map(list.map((a) => [a.address, Math.max(this.rank(a), ...this.tree(all, a.address).map((s) => RANK[kidStatus(s.t, this.listed)] ?? 0))]));
    const rankOf = (a) => urgency.get(a.address);
    if (byPriority) list = [...list].sort((x, y) => rankOf(y) - rankOf(x) || this.since(y) - this.since(x) || y.seq - x.seq);
    const pinned = list.filter((a) => a.pinned);
    const rest = list.filter((a) => !a.pinned);
    if (byFolder) {
      const names = [...new Set([...folders.names, ...rest.map(folderOf)])];
      rest.sort((a, b) => names.indexOf(folderOf(a)) - names.indexOf(folderOf(b)));
    }
    list = [...pinned, ...rest];
    setAgentOrder(list.map((a) => a.address));

    // Publish the picker order before folding. A pinned child appears once, at the top.
    const roots = new Set(list.map(a => a.address));
    const spaceById = new Map(sp.map(s => [s.id, s]));
    const published = new Set();
    const snapshot = list.flatMap(a => {
      const space = spaceById.get(a.space);
      const row = {
        address: a.address, name: nameOf(a), branch: branchOf(a), folder: folderOf(a),
        machine: space?.machine ?? null, path: space?.folder ?? "",
        program: a.program, status: a.status, compact: byPriority && !a.pinned, depth: 0,
      };
      return [row, ...this.tree(all, a.address).filter(s => !roots.has(s.t.address)).map(s => ({
        ...row, address: s.t.address, parent: s.t.parent, depth: s.lines.length,
        program: s.t.program, status: kidStatus(s.t, this.listed), compact: byPriority,
      }))];
    }).filter(row => {
      if (published.has(row.address)) return false;
      published.add(row.address);
      return true;
    });
    if (JSON.stringify(shared("pbogut.agents.rows")) !== JSON.stringify(snapshot)) {
      setShared("pbogut.agents.rows", snapshot);
    }

    const hints = shared("pbogut.sidebar.hints");
    this.hintState = hints?.mode === "agents" ? hints : null;
    const targets = new Set();
    const withKids = (a, i) => {
      const subs = collapsed ? [] : this.tree(all, a.address);
      targets.add(a.address);
      const r = row(a, i, subs);
      if (this.folded.has(a.address)) return [r];
      for (const s of subs) targets.add(s.t.address);
      return [r, ...subs.map((s) => this.subRow(t, s, shown, byPriority))];
    };

    // The fold chevron; folded, the count too, colored by the most urgent one.
    const fold = (a, subs) => {
      const sts = subs.map((s) => kidStatus(s.t, this.listed));
      const top = sts.reduce((m, s) => ((RANK[s] ?? 0) > (RANK[m] ?? 0) ? s : m), null);
      const open = !this.folded.has(a.address);
      return div()
        .id(`fold-${a.address}`)
        .h(18)
        .px(3)
        .gap(3)
        .flex()
        .items_center()
        .rounded(4)
        .text_size(11)
        .text_color(open ? t.dim : (t[top] ?? t.dim))
        .cursor_pointer()
        .hover((s) => s.bg(t.hover).text_color(t.foreground))
        .on_click((_e, cx) => {
          cx.stop_propagation();
          open ? this.folded.add(a.address) : this.folded.delete(a.address);
          cx.notify();
        })
        .child(svg(`mods/workspace-chrome/chevron-${open ? "down" : "right"}.svg`).size(11).flex_none())
        .when(!open, (el) => el.child(String(subs.length)));
    };

    const row = (a, i, subs = []) => {
      const pic = icon(a.program, 16, t.foreground);
      const name = nameOf(a);
      const branch = branchOf(a);
      // An agent on another machine (`vps/t7`) says which.
      const machine = a.address.includes("/") ? a.address.split("/")[0] : null;
      if (collapsed) {
        return h_flex().relative()
          .id(`ag-${a.address}`)
          .h(26)
          .px(8)
          .flex_none()
          .items_center()
          .gap(4)
          .tooltip([name, branch].filter(Boolean).join(" · "))
          .hover((s) => s.bg(t.hover))
          .on_click(() => run("pane.focus", { pane: a.pane }))
          .child(div().flex_1().min_w(0).whitespace_nowrap().text_right().text_color(t.muted).child(String(i + 1)))
          .child(h_flex().w(14).flex_none().items_center().justify_center().child(status(t, a, true)))
          .when(Boolean(this.hintState?.hints[a.address]), el => el.child(this.hintBadge(a.address, 4, t)));
      }
      const when = this.since(a);
      const idle = a.status === "idle" && !a.focused;
      const isPinned = a.pinned;
      const pin = div()
        .id(`pin-${a.address}`)
        .flex_none()
        .p(2)
        .rounded(4)
        .text_color(t.dim)
        .cursor_pointer()
        .hover((s) => s.bg(t.hover).text_color(t.foreground))
        .tooltip(isPinned ? "Unpin" : "Pin to the top")
        .on_click((_e, cx) => {
          cx.stop_propagation();
          run("terminal.pin", { terminal: a.address, pinned: !isPinned });
          // The row moves away from under the pointer, and no hover-out comes.
          this.hovered = null;
          cx.notify();
        })
        .child(svg(`mods/workspace-chrome/${isPinned ? "pin-off" : "pin"}.svg`).size(13));
      return h_flex().relative()
        .id(`ag-${a.address}`)
        .px(8)
        .h(30)
        .flex_none()
        .rounded(8)
        .items_center()
        .gap(9)
        .when(a.focused, (el) => el.bg(t.selected))
        .cursor_pointer()
        .hover((s) => s.bg(t.hover))
        .on_hover((on, cx) => {
          if (on) this.hovered = a.address;
          else if (this.hovered === a.address) this.hovered = null;
          cx.notify();
        })
        .on_click(() => run("pane.focus", { pane: a.pane }))
        .when(Boolean(pic), el => el.child(div().id(`agent-fold-${a.address}`)
          .when(subs.length > 0, el => el.on_click((_e, cx) => {
            cx.stop_propagation();
            this.folded.has(a.address) ? this.folded.delete(a.address) : this.folded.add(a.address);
            cx.notify();
          })).child(pic)))
        .child(h_flex().flex_1().min_w(0).gap(5).items_center()
          .child(div().flex_initial().min_w(40).truncate().tooltip(name).text_color(idle ? t.muted : t.foreground).child(name))
          .when(Boolean(branch), el => el.child(div().flex_1().min_w(40).truncate().text_size(11).text_color(t.dim)
            .tooltip(branch).child(`· ${branch.replace(/^\d{4}-\d{2}-\d{2}-(?=.)/, "")}`))))
        .when(Boolean(machine), el => el.child(div().text_size(10).text_color(t.dim).child(machine)))
        .when(subs.length > 0, el => el.child(fold(a, subs)))
        .when(this.hovered === a.address, el => el.child(pin))
        .when(this.hovered !== a.address && Boolean(when), el => el.child(div().flex_none().text_size(11).text_color(t.dim).child(duration(now - when))))
        .child(status(t, a, byPriority && !isPinned))
        .when(Boolean(this.hintState?.hints[a.address]), el => el.child(this.hintBadge(a.address, 8, t)));
    };

    // Folder mode nests priority sections under each folder. Pins stay above them.
    const groups = pinned.length ? [{ id: "pinned", label: "Pinned", status: null, members: pinned }] : [];
    for (const a of rest) {
      let sections = groups;
      const folder = folderOf(a);
      if (byFolder) {
        const id = JSON.stringify(["folder", folder]);
        if (groups.at(-1)?.id !== id) groups.push({ id, label: folder, members: [], sections: [] });
        const group = groups.at(-1);
        group.members.push(a);
        sections = group.sections;
      }
      const r = rankOf(a) || RANK.idle;
      const id = byFolder ? JSON.stringify(["folder-section", folder, r]) : byPriority ? `sec-${r}` : `sp-${a.space}`;
      if (sections.at(-1)?.id === id) sections.at(-1).members.push(a);
      else sections.push({ id, label: byPriority ? SECTION[r] : nameOf(a),
        status: byPriority ? SECTION_STATUS[r] : null, members: [a], nested: byFolder });
    }

    // A group's header; it folds the group. Folded, it says how many and the most urgent state.
    const header = (g) => {
      const open = !this.folded.has(g.id);
      const top = SECTION_STATUS[g.members.reduce((rank, a) => Math.max(rank, rankOf(a)), 0)];
      return h_flex()
        .id(g.id)
        .px(8)
        .when(g.nested, el => el.pl(20))
        .pt(8)
        .h(30)
        .flex_none()
        .gap(6)
        .items_center()
        .text_size(11)
        .font_medium()
        .cursor_pointer()
        .hover((s) => s.text_color(t.foreground))
        .on_click((_e, cx) => {
          open ? this.folded.add(g.id) : this.folded.delete(g.id);
          cx.notify();
        })
        .when(Boolean(g.sections), el => el.child(svg("mods/workspace-chrome/folder.svg").size(12).flex_none().text_color(t.dim)))
        .child(div().truncate().text_color(t[g.status] ?? t.dim).child(g.label))
        .when(byPriority || !open, (el) => el.child(div().text_color(t.dim).child(String(g.members.length))))
        .child(div().flex_1())
        .when(!open, (el) => el
          .when((!byPriority || Boolean(g.sections)) && Boolean(top), (el) => el.child(status(t, { status: top }, true)))
          .child(svg("mods/workspace-chrome/chevron-right.svg").size(11).flex_none().text_color(t.dim)))
        .when(Boolean(g.sections) && open, el => el.child(svg("mods/workspace-chrome/chevron-down.svg").size(11).flex_none().text_color(t.dim)));
    };
    const drawGroup = g => [header(g), ...(this.folded.has(g.id) ? []
      : g.sections ? g.sections.flatMap(drawGroup) : g.members.flatMap(withKids))];
    const rows = collapsed
      ? list.flatMap(withKids)
      : groups.flatMap(drawGroup);
    if (JSON.stringify([...targets]) !== JSON.stringify(shared("pbogut.agents.hintTargets"))) {
      setShared("pbogut.agents.hintTargets", [...targets]);
    }

    return v_flex()
      .size_full()
      .min_h(0)
      .bg(t.chrome)
      .border_t(1)
      .border_color(t.border)
      .text_size(13)
      .when(!collapsed, (el) =>
        el.child(
          h_flex()
            .px(16)
            .h(41)
            .pt(14)
            .pb(5)
            .flex_none()
            .items_center()
            .justify_between()
            .child(div().text_size(11.5).font_medium().text_color(t.dim).child("Agents"))
            .child(
              div()
                .id("ag-sort")
                .text_size(11)
                .text_color(t.dim)
                .hover((s) => s.text_color(t.foreground))
                .on_click(() => openOverlay({ mod: "pbogut-agents", kind: "popup", width: 200, height: 175, props: { sortMenu: true } }))
                .tooltip(`Sort agents: ${sort.label}`)
                .child(svg(`mods/workspace-chrome/${sort.icon}.svg`).size(14)),
            ),
        ),
      )
      .when(list.length === 0 && !collapsed, (el) =>
        el.child(div().px(12).text_size(12).text_color(t.dim).child("No agent status yet. Agents show up here when they report their status. Older versions and agents inside tmux may not.")),
      )
      .child(v_flex().id("ag-list").flex_1().min_h(0).px(collapsed ? 0 : 8).overflow_y_scrollbar().mode("always").children(rows))
      .when(collapsed, (el) =>
        el.child(
          h_flex()
            .h(28)
            .items_center()
            .justify_center()
            .child(
              div()
                .id("collapse")
                .text_size(13)
                .text_color(t.dim)
                .hover((s) => s.text_color(t.foreground))
                .on_click(toggleSidebar)
                .child("»"),
            ),
        ),
      );
  }
}
