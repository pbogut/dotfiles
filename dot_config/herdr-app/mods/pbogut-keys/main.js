import { View, div } from "gpui-kit";
import { h_flex } from "gpui-base";
import { checking, closeOverlay, layout, nextCommand, openOverlay, props, run, settings, theme } from "herdr";
import { prefixBindings } from "./bindings.js";

export default class Shortcuts extends View {
  init(_props, cx) {
    this.handle = cx.focus_handle();
    if (checking()) return;
    if (props()?.overlay) {
      this.handle.focus();
      return;
    }
    cx.spawn(async () => {
      for (;;) {
        const command = await nextCommand();
        if (command === `closed-${this.overlay}`) this.overlay = null;
        if (command !== "toggle" && command !== "copy") continue;
        const mod = command === "copy" ? "pbogut-copy" : "pbogut-keys";
        if (this.overlay) {
          closeOverlay(this.overlay);
          if (this.mod === mod) continue;
        }
        this.open(mod);
      }
    });
  }

  open(mod) {
    if (!this.width) return;
    const viewport = window.viewport_size();
    const zoom = settings().zoom ?? 1;
    const work = layout().children.find((node) => node.id === "work");
    const index = work.children.findIndex((node) => node.id === "prefix-anchor");
    const below = work.children.slice(index + 1)
      .reduce((height, node) => height + (node.hidden ? 0 : node.size?.px ?? 0), 0);
    this.mod = mod;
    this.overlay = openOverlay({
      mod, kind: "window", frame: "none",
      width: 1, height: 1, at: { x: 0, y: 0 },
      props: { left: (viewport.width - this.width) / zoom, bottom: below },
    });
  }

  dismiss() {
    closeOverlay(props().overlay);
  }

  close() {
    if (!checking() && props()?.overlay) run(`pbogut-keys.closed-${props().overlay}`);
  }

  onKey(event, cx) {
    cx.stop_propagation();
    if (event.keystroke === "escape") return this.dismiss();
    const action = prefixBindings[event.keystroke];
    if (action) {
      this.dismiss();
      run(...action);
    }
  }

  render() {
    // This zero-height layout copy measures the terminal area's width only.
    if (!props()?.overlay && !checking()) {
      return div().id("prefix-anchor").size_full()
        .on_size_change((size) => { this.width = size.width; });
    }
    const t = theme();
    const keycap = (key) => h_flex().h(22).min_w(22).px(5).justify_center().flex_shrink_0()
      .border_1().rounded(4).border_color(t.border).bg(t.surface)
      .text_color(t.accent).text_size(12).child(key);
    const hint = (key, label) => h_flex().gap(6).flex_shrink_0()
      .child(keycap(key)).child(div().child(label));
    const bar = h_flex().id("shortcuts").track_focus(this.handle).h(36)
      .overflow_hidden().on_key_down((event, cx) => this.onKey(event, cx))
      .on_mouse_down("left", (_event, cx) => cx.stop_propagation())
      .on_mouse_down_out(() => this.dismiss())
      .items_center().px(12).gap(24).whitespace_nowrap()
      .bg(t.popover).border_t_1().border_color(t.border)
      .text_color(t.foreground).text_size(13)
      .child(h_flex().flex_1().min_w(0).gap(24).overflow_hidden()
        .child(keycap("Ctrl+G"))
        .child(hint("v", "split right"))
        .child(hint("s", "split down"))
        .child(hint("c", "new tab"))
        .child(hint("x", "close project")))
      .child(hint("Esc", "cancel"));
    // Native relative positioning follows resizes without reopening the overlay.
    return div().id("shortcuts-overlay").relative().size_full()
      .on_mouse_down("left", (_event, cx) => cx.stop_propagation())
      .child(bar.absolute().left(props()?.left ?? 0).right(0).bottom(props()?.bottom ?? 0));
  }
}
