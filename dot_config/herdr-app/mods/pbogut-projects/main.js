import { View, div } from "gpui-kit";
import { v_flex, h_flex, InputState, Input, v_virtual_list, VirtualListScrollHandle } from "gpui-base";
import { appHome, checking, closeOverlay, exec, home, machines, props, readTextFile, run, settings, shared, spaces, theme } from "herdr";
import { machinePaths, pickerMachines } from "./machines.js";
import { openProject, projectLabel, projectRows } from "./projects.js";
import { createDatedWorktree } from "./worktrees.js";

export default class Projects extends View {
  init(_props, cx) {
    this.config = { root: "", aliases: {} };
    this.projects = [];
    this.machine = spaces().find((space) => space.active)?.machine ?? null;
    this.query = "";
    this.at = 0;
    this.scroll = VirtualListScrollHandle.new();
    this.handle = cx.focus_handle();
    this.input = InputState.new({ placeholder: "Find a project…" });
    this.input.on("change", (_e, cx) => {
      this.query = this.input.value();
      this.at = 0;
      this.scroll.scroll_to_item(0);
      cx.notify();
    });
    this.input.on("submit", (event, cx) => {
      const row = this.rows()[this.at];
      if (event.secondary) this.newWorktree(row, cx);
      else this.open(row);
    });
    this.branchInput = InputState.new({ placeholder: "New branch name…" });
    this.branchInput.on("submit", (_event, cx) => this.createWorktree(cx));
    // Override the native input's Tab action while the project list is shown.
    cx.bind_keys([
      { keystroke: "tab", action: "project-machine-next", context: "ProjectPicker > Input" },
      { keystroke: "shift-tab", action: "project-machine-prev", context: "ProjectPicker > Input" },
    ]);
    this.input.focus();
    if (checking()) return;
    this.load(cx);
  }

  cycleMachine(backwards, cx) {
    const choices = pickerMachines(machines(), this.machine);
    const index = choices.indexOf(this.machine);
    this.machine = choices[(index + (backwards ? choices.length - 1 : 1)) % choices.length];
    this.load(cx);
  }

  load(cx) {
    const request = this.request = {};
    const on = this.machine;
    this.config = { root: "", aliases: {} };
    this.projects = [];
    this.error = null;
    this.at = 0;
    this.scroll.scroll_to_item(0);
    this.loading = true;
    cx.notify();
    cx.spawn(async (cx) => {
      try {
        const paths = await machinePaths(on, exec, { home: home(), appHome: appHome() });
        const raw = await readTextFile(`${paths.appHome}/mods/pbogut-projects/projects.json`, { on });
        if (raw === null) throw new Error("Project settings are missing.");
        const config = JSON.parse(raw);
        if (!config.root?.startsWith("/")) throw new Error("Project root must be an absolute path.");
        const result = await exec("env", [`PROJECTS=${config.root}`, `${paths.home}/.scripts/ls-project`, "-f"], { on });
        if (result.code !== 0) throw new Error(result.stderr.trim() || "ls-project failed.");
        if (this.request !== request || this.opened) return;
        this.config = config;
        this.projects = result.stdout.split("\n").filter(Boolean);
      } catch (error) {
        if (this.request !== request || this.opened) return;
        this.error = String(error.message ?? error);
      }
      this.loading = false;
      cx.notify();
    });
  }

  rows() {
    return projectRows(spaces(), this.projects, this.config, this.query, this.machine, shared("pbogut.projects.spaces"));
  }

  close() {
    this.opened = true;
    closeOverlay(props().overlay);
  }

  open(row) {
    if (!row || this.opened) return;
    const command = openProject(row, spaces(), shared("pbogut.projects.spaces"));
    if (!command) return;
    this.close();
    run(...command);
  }

  newWorktree(row, cx) {
    if (!row || this.opened) return;
    this.worktree = row;
    this.worktreeError = null;
    this.branchInput.set_value("");
    this.branchInput.focus();
    cx.notify();
  }

  createWorktree(cx) {
    if (this.creating || this.opened) return;
    const name = this.branchInput.value();
    this.creating = true;
    this.worktreeError = null;
    cx.notify();
    cx.spawn(async (cx) => {
      try {
        const machine = this.worktree.machine ?? null;
        const paths = await machinePaths(machine, exec, { home: home(), appHome: appHome() });
        const folder = await createDatedWorktree(this.worktree, name, exec,
          `${paths.home}/.scripts/git-new-dated-worktree`);
        if (!this.opened) this.open({ folder, machine, label: projectLabel(folder, this.config) });
      } catch (error) {
        this.worktreeError = String(error.message ?? error);
      }
      this.creating = false;
      if (!this.opened) cx.notify();
    });
  }

  renderWorktree() {
    const t = theme();
    const button = (id, text, action) => div().id(id).px(12).py(7).rounded(7)
      .bg(t.raised).border(1).border_color(t.input).cursor_pointer()
      .hover((style) => style.bg(t.hover)).on_click(action).child(text);
    return v_flex().id("dated-worktree").track_focus(this.handle).w_full().p(18).gap(12)
      .bg(t.popover).text_color(t.foreground).text_size(13)
      .on_key_down((event, cx) => {
        if (event.key !== "escape") return;
        cx.stop_propagation();
        this.close();
      })
      .child(div().font_semibold().text_size(15).child(`New dated worktree · ${this.machine ?? "This computer"}`))
      .child(div().text_color(t.muted).truncate().child(this.worktree.folder || this.worktree.label))
      .child(Input.new(this.branchInput).h(36).px(10).items_center()
        .rounded(8).border(1).border_color(t.accent).bg(t.background))
      .child(div().text_size(11).text_color(t.dim).child("The script adds today's date. Spaces in the name become hyphens."))
      .when(Boolean(this.worktreeError), (el) => el.child(div().text_color(t.blocked).child(this.worktreeError)))
      .child(h_flex().justify_end().gap(8)
        .child(button("worktree-cancel", "Cancel", () => this.close()))
        .child(button("worktree-create", this.creating ? "Creating…" : "Create", (_event, cx) => this.createWorktree(cx))));
  }

  render() {
    if (this.worktree) return this.renderWorktree();
    const t = theme();
    const rows = this.rows();
    const height = Math.min(336, Math.max(48, rows.length * 48),
      Math.max(48, window.viewport_size().height / settings().zoom * 0.7 - 160));
    this.at = Math.max(0, Math.min(this.at, rows.length - 1));
    return v_flex()
      .id("projects").track_focus(this.handle).key_context("ProjectPicker").w_full().min_h(0).p(18).gap(10)
      .bg(t.popover).text_size(13).text_color(t.foreground)
      .on_action("project-machine-next", (_event, cx) => {
        cx.stop_propagation();
        this.cycleMachine(false, cx);
      })
      .on_action("project-machine-prev", (_event, cx) => {
        cx.stop_propagation();
        this.cycleMachine(true, cx);
      })
      .on_key_down((event, cx) => {
        if (event.keystroke === "tab" || event.keystroke === "shift-tab") {
          cx.stop_propagation();
          this.cycleMachine(event.keystroke === "shift-tab", cx);
          return;
        }
        const key = event.keystroke === "ctrl-j" ? "down" : event.keystroke === "ctrl-k" ? "up" : event.key;
        if (key === "escape") {
          cx.stop_propagation();
          return this.close();
        }
        if (!rows.length || !["up", "down"].includes(key)) return;
        this.at = (this.at + (key === "down" ? 1 : rows.length - 1)) % rows.length;
        this.scroll.scroll_to_item(this.at);
        cx.stop_propagation();
        cx.notify();
      })
      .child(h_flex().items_center().justify_between().flex_none()
        .child(div().flex_1().min_w(0).truncate().text_size(15).font_semibold().child(`Projects · ${this.machine ?? "This computer"}`))
        .child(div().text_size(11).text_color(t.dim).child(this.loading ? "Loading projects…" : `${rows.length} result${rows.length === 1 ? "" : "s"}`)))
      .child(Input.new(this.input).h(36).flex_none().px(10).items_center()
        .rounded(8).border(1).border_color(t.accent).bg(t.background).text_color(t.foreground))
      .when(Boolean(this.error), (el) => el.child(div().flex_none().text_size(11).text_color(t.blocked).child(this.error)))
      .child(v_flex().relative().h(height).flex_none()
        .child(rows.length
          ? v_virtual_list("project-list", rows.length, 48, (index) => rows[index].id ?? rows[index].folder,
            (range) => rows.slice(range.start, range.end).map((row, offset) =>
              v_flex().h(48).px(10).justify_center().rounded(7).cursor_pointer()
                .when(range.start + offset === this.at, (el) => el.bg(t.selected))
                .when(range.start + offset !== this.at, (el) => el.hover((style) => style.bg(t.hover)))
                .child(h_flex().items_center().gap(8)
                  .child(div().flex_1().min_w(0).truncate().when(row.active, (el) => el.font_semibold()).child(row.label))
                  .when(Boolean(row.id), (el) => el.child(div().flex_none().text_size(11).text_color(t.accent)
                    .child(row.machine ? `open · ${row.machine}` : "open"))))
                .child(div().truncate().text_size(11).text_color(t.dim).child(row.folder || "~"))))
            .size_full().track_scroll(this.scroll)
            .on_item_click((key) => this.open(this.rows().find((row) => (row.id ?? row.folder) === key)))
          : div().p(10).text_color(t.dim).child(this.loading ? "Loading projects…" : "No matching projects.")))
      .child(div().flex_none().text_size(11).text_color(t.dim).child("Tab / Shift+Tab machine · ↑↓ / Ctrl+J/K choose · Enter open · Ctrl+Enter worktree · Esc close"));
  }
}
