// Space-only version of Herdr 0.1.16's Apache-2.0 context menu, with the
// repository folder reset added. Rendered by this mod when opened as a popup.
import { div, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import {
  spaces,
  panes,
  exec,
  run,
  closeOverlay,
  openOverlay,
  theme,
  keys,
  shared,
  setShared,
} from "herdr";
import { ASSIGNMENTS } from "./folders.js";

export class FolderFilter {
  constructor(props, cx) {
    this.names = props.folderFilter;
    this.hints = props.folderHints;
    this.prefix = "";
    this.overlay = props.overlay;
    this.handle = cx.focus_handle();
    this.handle.focus();
  }

  toggle(name) {
    this.prefix = "";
    const hidden = new Set(shared("pbogut.folders.hidden") ?? []);
    if (hidden.has(name)) hidden.delete(name);
    else hidden.add(name);
    setShared("pbogut.folders.hidden", [...hidden]);
  }

  render() {
    const t = theme(),
      hidden = new Set(shared("pbogut.folders.hidden") ?? []);
    const names = this.names;
    return v_flex()
      .id("folder-filter")
      .w_full()
      .p(5)
      .bg(t.popover)
      .track_focus(this.handle)
      .on_key_down((event, cx) => {
        cx.stop_propagation();
        const key = event.keystroke;
        if (key === "escape") return closeOverlay(this.overlay);
        if (event.is_held) return;
        if (key === "backspace") this.prefix = this.prefix.slice(0, -1);
        else if (key?.length === 1) {
          const next = this.prefix + key;
          const match = names.find((name) => this.hints[name] === next);
          if (match !== undefined) this.toggle(match);
          else this.prefix = names.some((name) => this.hints[name].startsWith(next)) ? next : "";
        } else return;
        cx.notify();
      })
      .child(div().px(8).py(4).text_size(11).text_color(t.muted).child("Show folders"))
      .child(
        v_flex()
          .id("filter-options")
          .h(Math.min(302, names.length * 28))
          .flex_none()
          .overflow_y_scrollbar()
          .children(
            names.map((name) => {
              const on = !hidden.has(name);
              const hint = this.hints[name];
              return h_flex()
                .id(`filter-${name}`)
                .role("check_box")
                .checked(on)
                .accessibility_label(name)
                .h(28)
                .flex_none()
                .px(8)
                .gap(8)
                .items_center()
                .rounded(5)
                .cursor_pointer()
                .hover((s) => s.bg(t.hover))
                .on_click(() => this.toggle(name))
                .child(
                  h_flex()
                    .size(14)
                    .flex_none()
                    .items_center()
                    .justify_center()
                    .border_1()
                    .rounded(3)
                    .border_color(on ? t.accent : t.muted)
                    .when(on, (el) =>
                      el.child(
                        svg("mods/workspace-chrome/check.svg").size(12).text_color(t.accent),
                      ),
                    ),
                )
                .child(div().flex_1().truncate().text_size(13).text_color(t.foreground).child(name))
                .child(
                  div()
                    .px(4)
                    .rounded(3)
                    .border_1()
                    .text_size(11)
                    .text_color(hint.startsWith(this.prefix) ? t.accent : t.dim)
                    .border_color(t.border)
                    .child(hint.toUpperCase()),
                );
            }),
          ),
      );
  }
}

export default class SpaceMenu {
  constructor(props, cx) {
    this.target = props.spaceMenu;
    this.overlay = props.overlay;
    this.at = 0;
    this.git = null;
    this.handle = cx.focus_handle();
    this.handle.focus();
    const space = spaces().find((s) => s.id === this.target.id);
    const tabs = new Set((space?.tabs ?? []).map((tab) => tab.id));
    const folder = panes().find((pane) => tabs.has(pane.tab) && pane.cwd)?.cwd || space?.folder;
    if (folder)
      cx.spawn(async (cx) => {
        try {
          const top = await exec("git", ["rev-parse", "--show-toplevel"], {
            cwd: folder,
            on: space.machine,
          });
          const common = await exec(
            "git",
            ["rev-parse", "--path-format=absolute", "--git-common-dir"],
            { cwd: folder, on: space.machine },
          );
          if (top.code === 0 && common.code === 0)
            this.git = common.stdout.trim() === `${top.stdout.trim()}/.git` ? "main" : "linked";
        } catch {}
        cx.notify();
      });
  }

  items() {
    const { id, folderKey } = this.target;
    const assigned = folderKey && (shared(ASSIGNMENTS) ?? {})[folderKey] !== undefined;
    return [
      ...(assigned ? [["Use matching rules", "folder.reset", {}, "folder"]] : []),
      ["Rename", "space.rename", { id }, "square-pen"],
      ...(this.git
        ? [
            ["New worktree", "worktree", { space: id, action: "new" }, "git-branch"],
            ["Open worktree", "worktree", { space: id, action: "open" }, "git-branch"],
          ]
        : []),
      ...(this.git === "linked"
        ? [["Remove worktree", "worktree", { space: id, action: "remove" }, "git-branch"]]
        : []),
      ["Close", "space.close", { id }, "x"],
    ];
  }

  choose(index) {
    const item = this.items()[index];
    if (!item) return;
    closeOverlay(this.overlay);
    if (item[1] === "folder.reset") {
      const assignments = { ...(shared(ASSIGNMENTS) ?? {}) };
      delete assignments[this.target.folderKey];
      setShared(ASSIGNMENTS, assignments);
    } else if (item[1] === "worktree") {
      openOverlay({
        mod: "worktree",
        kind: "dialog",
        ...(item[2].action === "open" ? { width: 560, height: 480 } : { width: 440, height: 260 }),
        props: item[2],
      });
    } else run(item[1], item[2]);
  }

  render(cx) {
    const t = theme(),
      list = this.items();
    return v_flex()
      .id("space-menu")
      .track_focus(this.handle)
      .w_full()
      .min_h(0)
      .p(5)
      .bg(t.popover)
      .text_size(12.8)
      .on_key_down((event, cx) => {
        if (event.key === "down") this.at = (this.at + 1) % list.length;
        else if (event.key === "up") this.at = (this.at + list.length - 1) % list.length;
        else if (event.key === "enter") this.choose(this.at);
        else if (event.key === "escape") closeOverlay(this.overlay);
        else return;
        cx.notify();
      })
      .children(
        list.map((item, index) => {
          const shortcut = keys().find((key) => key.section === "global" && key.action === item[1]);
          return v_flex()
            .when(item[1] === "space.close", (el) => el.child(div().mx(7).my(4).h(1).bg(t.border)))
            .child(
              h_flex()
                .id(`space-menu-${index}`)
                .h(31)
                .px(8)
                .gap(9)
                .rounded(7)
                .items_center()
                .text_color(t.foreground)
                .when(index === this.at, (el) => el.bg(t.selected))
                .hover((el) => el.bg(t.hover))
                .on_click(() => this.choose(index))
                .child(
                  svg(`mods/workspace-chrome/${item[3]}.svg`)
                    .size(14)
                    .flex_none()
                    .text_color(t.muted),
                )
                .child(div().flex_1().child(item[0]))
                .child(
                  div()
                    .text_size(11)
                    .text_color(t.dim)
                    .child(shortcut?.keys ?? ""),
                ),
            );
        }),
      );
  }
}
