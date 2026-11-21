import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input, v_virtual_list, VirtualListScrollHandle } from "gpui-base";
import { closeOverlay, props, run, settings, shared, spaces, theme } from "herdr";

export default class SpacePicker extends View {
  init(_props, cx) {
    this.query = "";
    this.at = 0;
    this.scroll = VirtualListScrollHandle.new();
    this.handle = cx.focus_handle();
    this.input = InputState.new({ placeholder: "Find a space…" });
    this.input.on("change", (_event, cx) => {
      this.query = this.input.value();
      this.at = 0;
      this.selected = null;
      this.scroll.scroll_to_item(0);
      cx.notify();
    });
    this.input.on("submit", () => this.open(this.rows().find(row => row.w.id === this.selected)));
    this.input.focus();
  }

  rows() {
    const live = new Map(spaces().map(w => [w.id, w]));
    const rows = [];
    for (const row of shared("pbogut.spaces.rows") ?? []) {
      const w = live.get(row.id);
      if (!w) continue;
      rows.push({ ...row, w });
      live.delete(row.id);
    }
    // New spaces remain reachable while the sidebar resolves their Git data.
    for (const w of live.values()) rows.push({ w, name: w.name });
    const words = this.query.toLowerCase().trim().split(/\s+/).filter(Boolean);
    const hidden = new Set(shared("pbogut.folders.hidden") ?? []);
    const fallback = shared("pbogut.spaces.folders")?.fallback ?? "other";
    return rows.filter(row => {
      if (hidden.has(row.folder ?? fallback)) return false;
      const text = [row.name, row.w.name, row.w.folder, row.w.machine, row.folder, row.branch].join(" ").toLowerCase();
      return words.every(word => text.includes(word));
    });
  }

  dismiss() {
    this.closed = true;
    closeOverlay(props().overlay);
  }

  close() {
    if (props()?.sidebarPicker) run(`pbogut-keys.closed-${props().overlay}`);
  }

  open(row) {
    if (!row || this.closed || !spaces().some(w => w.id === row.w.id)) return;
    this.dismiss();
    run("space.select", { id: row.w.id });
  }

  render() {
    const t = theme();
    const rows = this.rows();
    const index = this.selected === undefined ? rows.findIndex(row => row.w.active)
      : rows.findIndex(row => row.w.id === this.selected);
    this.at = Math.max(0, Math.min(index < 0 ? this.at : index, rows.length - 1));
    this.selected = rows[this.at]?.w.id ?? null;
    const reveal = JSON.stringify([this.selected, this.at]);
    if (reveal !== this.revealed) {
      this.revealed = reveal;
      this.scroll.scroll_to_item(this.at);
    }
    const height = Math.min(336, Math.max(48, rows.length * 48),
      Math.max(48, window.viewport_size().height / settings().zoom * 0.7 - 160));
    return v_flex().id("space-picker").track_focus(this.handle).w_full().min_h(0).p(18).gap(10)
      .bg(t.popover).text_size(13).text_color(t.foreground)
      .on_key_down((event, cx) => {
        const key = event.keystroke === "ctrl-j" ? "down" : event.keystroke === "ctrl-k" ? "up" : event.key;
        if (key === "escape") {
          cx.stop_propagation();
          return this.dismiss();
        }
        if (!rows.length || !["up", "down"].includes(key)) return;
        this.at = (this.at + (key === "down" ? 1 : rows.length - 1)) % rows.length;
        this.selected = rows[this.at].w.id;
        this.scroll.scroll_to_item(this.at);
        cx.stop_propagation();
        cx.notify();
      })
      .child(h_flex().items_center().justify_between().flex_none()
        .child(div().text_size(15).font_semibold().child("Spaces"))
        .child(div().text_size(11).text_color(t.dim).child(`${rows.length} space${rows.length === 1 ? "" : "s"}`)))
      .child(Input.new(this.input).h(36).flex_none().px(10).items_center()
        .rounded(8).border(1).border_color(t.accent).bg(t.background).text_color(t.foreground))
      .child(v_flex().relative().h(height).flex_none()
        .child(rows.length
          ? v_virtual_list("space-picker-list", rows.length, 48, index => rows[index].w.id,
            range => rows.slice(range.start, range.end).map((row, offset) =>
              v_flex().h(48).px(10).justify_center().rounded(7).cursor_pointer()
                .when(range.start + offset === this.at, el => el.bg(t.selected))
                .when(range.start + offset !== this.at, el => el.hover(style => style.bg(t.hover)))
                .child(h_flex().items_center().gap(8)
                  .when(Boolean(row.tree), el => el.pl(22))
                  .when(Boolean(row.icon), el => el.child(row.icon.svg
                    ? svg(row.icon.svg).size(13).flex_none().text_color(t.dim)
                    : h_flex().size(18).flex_none().rounded(5).bg(row.icon.color).items_center().justify_center()
                      .text_size(10.5).font_bold().text_color("#ffffff").child(row.icon.initial)))
                  .child(div().flex_1().min_w(0).truncate().when(row.w.active, el => el.font_semibold()).child(row.name))
                  .when(Boolean(row.branch), el => el.child(div().max_w(240).truncate().text_size(11).text_color(t.dim)
                    .tooltip(row.branch).child(row.branch.replace(/^\d{4}-\d{2}-\d{2}-(?=.)/, ""))))
                  .when(row.ahead > 0, el => el.child(div().flex_none().text_color(t.ansi2).child(`↑${row.ahead}`)))
                  .when(row.behind > 0, el => el.child(div().flex_none().text_color(t.ansi1).child(`↓${row.behind}`))))
                .child(div().truncate().text_size(11).text_color(t.dim)
                  .child([row.w.machine ?? "This computer", row.folder, row.w.folder].filter(Boolean).join(" · ")))))
            .size_full().track_scroll(this.scroll)
            .on_item_click(id => this.open(this.rows().find(row => row.w.id === id)))
          : div().p(10).text_color(t.dim).child("No matching spaces.")))
      .child(div().flex_none().text_size(11).text_color(t.dim).child("↑↓ / Ctrl+J/K choose · Enter switch · Esc close"));
  }
}
