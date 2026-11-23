import { View, div } from "gpui-kit";
import { h_flex, v_flex, Input, InputState } from "gpui-base";
import { closeOverlay, props, run, theme } from "herdr";

export default class TaskPicker extends View {
  init(_props, cx) {
    this.prefix = "";
    this.tasks = props()?.tasks ?? [];
    this.input = InputState.new({ placeholder: "Search tasks by name" });
    this.input.on("change", (_event, cx) => {
      this.at = 0;
      cx.notify();
    });
    this.input.on("submit", () => this.choose(this.visibleTasks()[this.at]?.name));
    // The popup normally consumes Escape before on_key_down sees it.
    cx.bind_keys([
      { keystroke: "escape", action: "task-search-back", context: "TaskSearch > Input" },
    ]);
    this.handle = cx.focus_handle();
    if (props()?.overlay) this.handle.focus();
  }

  visibleTasks() {
    if (!this.searching) return this.tasks;
    const query = this.input.value().toLowerCase();
    return this.tasks.filter(({ name }) => name.toLowerCase().includes(query));
  }

  openSearch(cx) {
    this.prefix = "";
    this.searching = true;
    this.at = 0;
    this.input.set_value("");
    this.input.focus();
    cx.notify();
  }

  onKey(event, cx) {
    const key = event.keystroke;
    if (this.searching) {
      if (!["down", "ctrl-j", "up", "ctrl-k"].includes(key)) return;
      const count = this.visibleTasks().length;
      const step = key === "down" || key === "ctrl-j" ? 1 : -1;
      if (count) this.at = (this.at + step + count) % count;
      cx.stop_propagation();
      cx.notify();
      return;
    }
    cx.stop_propagation();
    if (key === "escape") {
      closeOverlay(props().overlay);
      return;
    }
    if (key === "/") return this.openSearch(cx);
    if (key === "backspace") this.prefix = this.prefix.slice(0, -1);
    else {
      if (key.length !== 1 || event.is_held) return;
      const prefix = this.prefix + key;
      const match = this.tasks.find((task) => task.hint === prefix);
      if (match) {
        this.choose(match.name);
        return;
      }
      if (!this.tasks.some((task) => task.hint.startsWith(prefix))) return;
      this.prefix = prefix;
    }
    cx.notify();
  }

  choose(name) {
    if (!name || this.chosen) return;
    this.chosen = true;
    const { space, overlay } = props();
    closeOverlay(overlay);
    run(`pbogut-tabs.task@${encodeURIComponent(JSON.stringify({ space, name }))}`);
  }

  render() {
    const t = theme(),
      tasks = this.visibleTasks(),
      columns = [];
    const rows = props()?.rowsPerColumn || this.tasks.length || 1;
    for (let start = 0; start < tasks.length; start += rows) {
      columns.push(
        v_flex()
          .flex_1()
          .min_w(0)
          .children(
            tasks.slice(start, start + rows).map(({ name, hint }, i) => {
              const matches = hint.startsWith(this.prefix);
              return h_flex()
                .id(`task-${start + i}`)
                .h(28)
                .items_center()
                .gap(8)
                .px(4)
                .rounded(4)
                .cursor_pointer()
                .when(this.searching && start + i === this.at, (el) => el.bg(t.hover))
                .hover((style) => style.bg(t.hover))
                .on_click(() => this.choose(name))
                .when(!this.searching, (el) =>
                  el.child(
                    h_flex()
                      .min_w(24)
                      .h(20)
                      .px(4)
                      .flex_none()
                      .items_center()
                      .justify_center()
                      .font_family("JetBrainsMono Nerd Font Mono")
                      .text_size(12)
                      .whitespace_nowrap()
                      .bg(t.surface)
                      .rounded(4)
                      .border_1()
                      .border_color(matches ? t.accent : t.border)
                      .when(matches && !!this.prefix, (el) =>
                        el.child(div().text_color(t.dim).child(this.prefix.toUpperCase())),
                      )
                      .child(
                        div()
                          .font_semibold()
                          .text_color(matches ? t.accent : t.dim)
                          .child((matches ? hint.slice(this.prefix.length) : hint).toUpperCase()),
                      ),
                  ),
                )
                .child(
                  div()
                    .min_w(0)
                    .truncate()
                    .tooltip(name)
                    .text_color(matches ? t.foreground : t.dim)
                    .child(name),
                );
            }),
          ),
      );
    }
    return v_flex()
      .id("task-picker")
      .track_focus(this.handle)
      .w_full()
      .min_h(0)
      .p(16)
      .gap(8)
      .bg(t.popover)
      .text_color(t.foreground)
      .text_size(13)
      .when(this.searching, (el) =>
        el.key_context("TaskSearch").on_action("task-search-back", (_event, cx) => {
          cx.stop_propagation();
          this.searching = false;
          this.handle.focus();
          cx.notify();
        }),
      )
      .on_key_down((event, cx) => this.onKey(event, cx))
      .child(
        this.searching
          ? Input.new(this.input)
              .h(28)
              .px(6)
              .items_center()
              .rounded(4)
              .border(1)
              .border_color(t.accent)
          : h_flex()
              .items_center()
              .justify_between()
              .child(div().font_semibold().child("Run project task"))
              .child(
                div()
                  .id("task-search")
                  .text_color(t.dim)
                  .cursor_pointer()
                  .hover((style) => style.text_color(t.accent))
                  .on_click((_event, cx) => this.openSearch(cx))
                  .child("/ Search by name"),
              ),
      )
      .child(
        tasks.length
          ? h_flex().items_start().gap(8).w_full().children(columns)
          : div().text_color(t.dim).child("No matching tasks"),
      );
  }
}
