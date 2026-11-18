import { View, div } from "gpui-kit";
import { v_flex, h_flex, InputState, Input, v_virtual_list, VirtualListScrollHandle } from "gpui-base";
import { agents, terminals, focused, openOverlay, closeOverlay, props, run, settings, shared, spaces, theme } from "herdr";
import { icon, status } from "./appearance.js";

export function openPicker() {
  const viewport = window.viewport_size().width / settings().zoom;
  const width = Math.min(680, viewport - 32);
  openOverlay({ mod: "pbogut-agents", props: { picker: true }, kind: "popup", width, height: 0.7,
    at: { x: (viewport - width) / 2, y: 40 } });
}

export default class AgentPicker extends View {
  init(_props, cx) {
    this.query = "";
    this.at = 0;
    this.selected = focused()?.agent;
    this.scroll = VirtualListScrollHandle.new();
    this.handle = cx.focus_handle();
    this.input = InputState.new({ placeholder: "Find an agent…" });
    this.input.on("change", (_event, cx) => {
      this.query = this.input.value();
      this.at = 0;
      this.selected = null;
      this.scroll.scroll_to_item(0);
      cx.notify();
    });
    this.input.on("submit", () => this.open(this.rows().find(row => row.address === this.selected)));
    this.input.focus();
  }

  rows() {
    const live = new Map(agents().map(a => [a.address, a]));
    const children = new Map(terminals().filter(t => t.state === "live" && t.parent).map(t => [t.address, t]));
    const rows = [];
    for (const row of shared("pbogut.agents.rows") ?? []) {
      const a = live.get(row.address) ?? (row.parent && children.get(row.address));
      if (!a) continue;
      let st = a.status;
      if (row.parent) st = st === "error" ? "blocked" : st === "done" ? "idle" : st;
      rows.push({ ...row, program: a.program, status: st });
      live.delete(row.address);
    }
    // New agents stay reachable while the sidebar resolves their order.
    const sp = new Map(spaces().map(s => [s.id, s]));
    const labels = new Map((shared("pbogut.spaces.rows") ?? []).map(row => [row.id, row]));
    for (const a of live.values()) {
      const space = sp.get(a.space), label = labels.get(a.space);
      rows.push({
        address: a.address, name: label?.name || a.space_name, branch: label?.branch ?? "",
        folder: label?.folder ?? shared("pbogut.spaces.folders")?.fallback ?? "other",
        machine: space?.machine ?? null, path: space?.folder ?? "", program: a.program, status: a.status,
      });
    }
    const words = this.query.toLowerCase().trim().split(/\s+/).filter(Boolean);
    return rows.filter(row => {
      const text = [row.name, row.branch, row.machine ?? "This computer", row.folder, row.path, row.program?.name, row.address]
        .join(" ").toLowerCase();
      return words.every(word => text.includes(word));
    });
  }

  close() {
    this.closed = true;
    closeOverlay(props().overlay);
  }

  open(row) {
    if (!row || this.closed) return;
    if (!agents().some(a => a.address === row.address)
      && !(row.parent && terminals().some(t => t.address === row.address && t.state === "live" && t.parent))) return;
    this.close();
    run("agent.focus", { terminal: row.address });
  }

  render() {
    const t = theme();
    const rows = this.rows();
    const current = focused()?.agent;
    const index = rows.findIndex(row => row.address === this.selected);
    this.at = Math.max(0, Math.min(index < 0 ? this.at : index, rows.length - 1));
    this.selected = rows[this.at]?.address ?? null;
    const reveal = JSON.stringify([this.selected, this.at]);
    if (reveal !== this.revealed) {
      this.revealed = reveal;
      this.scroll.scroll_to_item(this.at);
    }
    const height = Math.min(336, Math.max(48, rows.length * 48),
      Math.max(48, window.viewport_size().height / settings().zoom * 0.7 - 160));
    return v_flex().id("agent-picker").track_focus(this.handle).w_full().min_h(0).p(18).gap(10)
      .bg(t.popover).text_size(13).text_color(t.foreground)
      .on_key_down((event, cx) => {
        const key = event.keystroke === "ctrl-j" ? "down" : event.keystroke === "ctrl-k" ? "up" : event.key;
        if (key === "escape") {
          cx.stop_propagation();
          return this.close();
        }
        if (!rows.length || !["up", "down"].includes(key)) return;
        this.at = (this.at + (key === "down" ? 1 : rows.length - 1)) % rows.length;
        this.selected = rows[this.at].address;
        this.scroll.scroll_to_item(this.at);
        cx.stop_propagation();
        cx.notify();
      })
      .child(h_flex().items_center().justify_between().flex_none()
        .child(div().text_size(15).font_semibold().child("Agents"))
        .child(div().text_size(11).text_color(t.dim).child(`${rows.length} agent${rows.length === 1 ? "" : "s"}`)))
      .child(Input.new(this.input).h(36).flex_none().px(10).items_center()
        .rounded(8).border(1).border_color(t.accent).bg(t.background).text_color(t.foreground))
      .child(v_flex().relative().h(height).flex_none()
        .child(rows.length
          ? v_virtual_list("agent-picker-list", rows.length, 48, index => rows[index].address,
            range => rows.slice(range.start, range.end).map((row, offset) => {
              const pic = icon(row.program, row.parent ? 14 : 16, t.foreground);
              const detail = [row.machine ?? "This computer", row.folder, row.path].filter(Boolean).join(" · ");
              return v_flex().id(`agent-picker-${row.address}`).h(48).px(10).justify_center().rounded(7).cursor_pointer()
                .when(range.start + offset === this.at, el => el.bg(t.selected))
                .when(range.start + offset !== this.at, el => el.hover(style => style.bg(t.hover)))
                .child(h_flex().items_center().gap(8).pl((row.depth ?? 0) * 12)
                  .when(Boolean(pic), el => el.child(pic))
                  .child(div().flex_1().min_w(0).truncate().tooltip(row.name)
                    .text_color(row.status === "idle" && row.address !== current ? t.muted : t.foreground)
                    .when(row.address === current, el => el.font_semibold()).child(row.name))
                  .when(Boolean(row.branch), el => el.child(div().max_w(240).truncate().text_size(11).text_color(t.dim)
                    .tooltip(row.branch).child(row.branch.replace(/^\d{4}-\d{2}-\d{2}-(?=.)/, ""))))
                  .child(status(t, row, row.compact)))
                .child(div().truncate().text_size(11).text_color(t.dim).tooltip(detail).child(detail));
            }))
            .size_full().track_scroll(this.scroll)
            .on_item_click(address => this.open(this.rows().find(row => row.address === address)))
          : div().p(10).text_size(12).text_color(t.dim).child("No matching agents.")))
      .child(div().flex_none().text_size(11).text_color(t.dim).child("↑↓ / Ctrl+J/K choose · Enter switch · Esc close"));
  }
}
