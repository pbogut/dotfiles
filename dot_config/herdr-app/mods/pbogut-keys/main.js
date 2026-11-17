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
        if (command !== "toggle") continue;
        if (this.overlay) closeOverlay(this.overlay);
        else this.open();
      }
    });
  }

  open() {
    if (!this.width) return;
    const viewport = window.viewport_size();
    const zoom = settings().zoom ?? 1;
    const work = layout().children.find((node) => node.id === "work");
    const index = work.children.findIndex((node) => node.id === "prefix-anchor");
    const below = work.children.slice(index + 1)
      .reduce((height, node) => height + (node.hidden ? 0 : node.size?.px ?? 0), 0);
    this.overlay = openOverlay({
      mod: "pbogut-keys", kind: "window", frame: "none",
      width: this.width / zoom, height: 36,
      at: { x: viewport.width - this.width, y: viewport.height - (below + 36) * zoom },
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
    const keycap = (key) => h_flex().h(22).min_w(22).px(5).justify_center()
      .border_1().rounded(4).border_color(t.border).bg(t.surface)
      .text_color(t.accent).text_size(12).child(key);
    const hint = (key, label) => h_flex().gap(6)
      .child(keycap(key)).child(div().child(label));
    return h_flex().id("shortcuts").track_focus(this.handle).w_full().h(36)
      .overflow_hidden().on_key_down((event, cx) => this.onKey(event, cx))
      .on_mouse_down("left", (_event, cx) => cx.stop_propagation())
      .on_mouse_down_out(() => this.dismiss())
      .items_center().px(12).gap(24)
      .bg(t.popover).border_t_1().border_color(t.border)
      .text_color(t.foreground).text_size(13)
      .child(keycap("Ctrl+G"))
      .child(hint("v", "split right"))
      .child(hint("s", "split down"))
      .child(hint("c", "new tab"))
      .child(div().flex_1())
      .child(hint("Esc", "cancel"));
  }
}
