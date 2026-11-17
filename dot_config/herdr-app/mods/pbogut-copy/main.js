import { View, div } from "gpui-kit";
import { v_flex } from "gpui-base";
import { checking, closeOverlay, focused, props, run, terminals, theme } from "herdr";

const directions = {
  h: "left", left: "left",
  j: "down", down: "down",
  k: "up", up: "up",
  l: "right", right: "right",
  pageup: "page_up", "ctrl-b": "page_up",
  pagedown: "page_down", "ctrl-f": "page_down",
  home: "home", "shift-g": "end", end: "end",
  "0": "line_start", "$": "line_end", "shift-4": "line_end",
};

export default class CopyMode extends View {
  init(_props, cx) {
    this.handle = cx.focus_handle();
    this.terminal = focused()?.terminal;
    this.selecting = false;
    if (checking()) return;
    if (!this.terminal) return this.dismiss();
    this.handle.focus();
    run("terminal.select", { terminal: this.terminal, at: "cursor" });
  }

  dismiss() {
    closeOverlay(props().overlay);
  }

  close() {
    if (!this.terminal || checking()) return;
    run("terminal.clear_selection", { terminal: this.terminal });
    run("terminal.scroll", { terminal: this.terminal, to: "bottom" });
  }

  selection() {
    return terminals().find((terminal) => terminal.address === this.terminal)?.selection;
  }

  onKey(event, cx) {
    cx.stop_propagation();
    const key = event.keystroke.replace(/([A-Z])$/, (letter) => letter.toLowerCase());
    if (["escape", "ctrl-c", "q"].includes(key)) return this.dismiss();
    if (key === "y" || key === "enter") {
      run("terminal.copy");
      return this.dismiss();
    }
    if (key === "v" || key === "space" || key === "shift-v") {
      const at = this.selection()?.end;
      this.selecting = key === "shift-v" || !this.selecting;
      this.collapseFrom = null;
      if (at) run("terminal.select", {
        terminal: this.terminal, at, mode: key === "shift-v" ? "line" : "cell",
      });
      cx.notify();
      return;
    }
    const direction = key === "g" && this.lastKey === "g" ? "home" : directions[key];
    this.lastKey = key;
    if (!direction) return;
    // Collapse after the host reports movement; keep the anchor while selecting.
    this.collapseFrom = this.selecting ? null : JSON.stringify(this.selection()?.end);
    run("terminal.adjust_selection", { terminal: this.terminal, direction });
    cx.notify();
  }

  render() {
    const t = theme();
    if (this.collapseFrom) {
      const end = this.selection()?.end;
      if (end && JSON.stringify(end) !== this.collapseFrom) {
        this.collapseFrom = null;
        run("terminal.select", { terminal: this.terminal, at: end });
      }
    }
    return v_flex().id("copy-mode").track_focus(this.handle).w_full()
      .p(12).gap(6).bg(t.popover).text_color(t.foreground).text_size(13)
      .on_key_down((event, cx) => this.onKey(event, cx))
      .child(div().font_semibold().text_color(t.accent)
        .child(`Copy mode${this.selecting ? " · selecting" : ""}`))
      .child(div().child("h j k l / arrows: move    v / Space: select    V: select lines"))
      .child(div().child("0 / $: line edges    gg / G: history edges    PgUp / PgDn: page"))
      .child(div().child("y / Enter: copy    Esc / q: cancel"));
  }
}
