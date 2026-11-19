import { View, div } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { closeOverlay, props, run, theme } from "herdr";

export default class TaskPicker extends View {
  init(_props, cx) {
    this.prefix = "";
    this.tasks = props()?.tasks ?? [];
    this.handle = cx.focus_handle();
    if (props()?.overlay) this.handle.focus();
  }

  onKey(event, cx) {
    cx.stop_propagation();
    const key = event.keystroke;
    if (key === "escape") { closeOverlay(props().overlay); return; }
    if (key === "backspace") this.prefix = this.prefix.slice(0, -1);
    else {
      if (key.length !== 1 || event.is_held) return;
      const prefix = this.prefix + key;
      const match = this.tasks.find(task => task.hint === prefix);
      if (match) { this.choose(match.name); return; }
      if (!this.tasks.some(task => task.hint.startsWith(prefix))) return;
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
    const t = theme(), columns = [];
    const rows = props()?.rowsPerColumn || this.tasks.length || 1;
    for (let start = 0; start < this.tasks.length; start += rows) {
      columns.push(v_flex().flex_1().min_w(0).children(this.tasks.slice(start, start + rows).map(({ name, hint }, i) => {
        const matches = hint.startsWith(this.prefix);
        return h_flex().id(`task-${start + i}`).h(28).items_center().gap(8).px(4).rounded(4)
          .cursor_pointer().hover(style => style.bg(t.hover)).on_click(() => this.choose(name))
          .child(h_flex().min_w(24).h(20).px(4).flex_none().items_center().justify_center()
            .bg(t.surface).rounded(4).border_1().border_color(matches ? t.accent : t.border)
            .when(matches && !!this.prefix, el => el.child(div().text_color(t.dim).child(this.prefix)))
            .child(div().font_semibold().text_color(matches ? t.accent : t.dim)
              .child(matches ? hint.slice(this.prefix.length) : hint)))
          .child(div().min_w(0).truncate().tooltip(name).text_color(matches ? t.foreground : t.dim).child(name));
      })));
    }
    return v_flex().id("task-picker").track_focus(this.handle).w_full().min_h(0).p(16).gap(8)
      .bg(t.popover).text_color(t.foreground).text_size(13)
      .on_key_down((event, cx) => this.onKey(event, cx))
      .child(div().font_semibold().child("Run project task"))
      .child(h_flex().items_start().gap(8).w_full().children(columns));
  }
}
