import { View, div } from "gpui-kit";
import { h_flex } from "gpui-base";
import { agents, appHome, checking, closeOverlay, exec, focused, layout, nextCommand, notify, openOverlay, props, run, settings, shared, setShared, spaces, terminals, theme, window as appWindow } from "herdr";
import { pickers, prefixBindings, sidebarHints } from "./bindings.js";

const STATE = "pbogut.sidebar.hints";

export default class Shortcuts extends View {
  init(_props, cx) {
    this.handle = cx.focus_handle();
    if (checking()) return;
    if (props()?.overlay) {
      const { mode, overlay, hints } = props();
      if (hints) {
        const current = mode === "spaces" ? spaces().find(s => s.active)?.id : focused()?.agent;
        const selected = Object.hasOwn(hints, current) ? current : Object.keys(hints)[0] ?? null;
        setShared(STATE, { overlay, mode, hints, prefix: "", selected });
      }
      this.handle.focus();
      // Frameless windows don't dismiss on blur. Only watch while hints are open.
      if (hints) cx.timer.every(75, () => {
        if (!this.closing && (!this.handle.is_focused() || !appWindow().active)) this.dismiss();
      });
      return;
    }
    if (shared(STATE)) setShared(STATE, null);
    cx.spawn(async (cx) => {
      for (;;) {
        const command = await nextCommand();
        if (command === `closed-${this.overlay}`) this.overlay = null;
        if (command === `closed-${this.picker}`) this.picker = null;
        if (this.overlay && command === `released-${this.overlay}`) {
          this.released = true;
          if (this.pending === 1) {
            closeOverlay(this.overlay);
            this.overlay = null;
            this.openPicker(this.mode);
          }
          continue;
        }
        if (command !== "toggle" && command !== "copy" && !Object.hasOwn(pickers, command)) continue;
        if (this.picker) {
          closeOverlay(this.picker);
          this.picker = null;
          if (this.mode === command) continue;
        }
        const mod = command === "copy" ? "pbogut-copy" : "pbogut-keys";
        if (this.overlay) {
          // A rapid pair can reach the layout before the bar receives a key-up.
          // Later, native shortcut commands include auto-repeat but no held flag.
          if (this.mode === command && Object.hasOwn(pickers, command) &&
              Date.now() - this.opened > 100 && !this.released) {
            this.pending++;
            continue;
          }
          closeOverlay(this.overlay);
          this.overlay = null;
          if (this.mode === command) {
            if (Object.hasOwn(pickers, command)) { this.openPicker(command); continue; }
            const terminal = command === "toggle" && focused()?.terminal;
            if (terminal) cx.spawn(async () => {
              try {
                const result = await exec("node", [
                  `${appHome()}/mods/pbogut-keys/send-ctrl-g.mjs`, terminal, settings().core || "hc",
                ], { timeout: 3000 });
                if (result.code !== 0) throw new Error(result.stderr.trim() || "The terminal rejected the key.");
              } catch (error) {
                notify({ title: "Could not send Ctrl+G", body: String(error.message ?? error), level: "error" });
              }
            });
            continue;
          }
        }
        if (Object.hasOwn(pickers, command) && layout().children.find(n => n.id === "sidebar")?.hidden) {
          this.openPicker(command);
          continue;
        }
        this.open(mod, command);
      }
    });
  }

  openPicker(mode) {
    const viewport = window.viewport_size().width / (settings().zoom ?? 1);
    const width = Math.min(680, viewport - 32);
    this.mode = mode;
    this.picker = openOverlay({ mod: pickers[mode], kind: "popup", width, height: 0.7,
      at: { x: (viewport - width) / 2, y: 40 }, props: { sidebarPicker: true, picker: mode === "agents" } });
  }

  open(mod, mode) {
    if (!this.width) return;
    const viewport = window.viewport_size();
    const zoom = settings().zoom ?? 1;
    const work = layout().children.find((node) => node.id === "work");
    const index = work.children.findIndex((node) => node.id === "prefix-anchor");
    const below = work.children.slice(index + 1)
      .reduce((height, node) => height + (node.hidden ? 0 : node.size?.px ?? 0), 0);
    this.mode = mode;
    this.opened = Date.now();
    this.released = false;
    this.pending = 0;
    const hints = Object.hasOwn(pickers, mode) ? sidebarHints(shared(`pbogut.${mode}.hintTargets`) ?? []) : null;
    this.overlay = openOverlay({
      mod, kind: "window", frame: "none",
      width: 1, height: 1, at: { x: 0, y: 0 },
      props: { mode, hints, left: (viewport.width - this.width) / zoom, bottom: below },
    });
  }

  dismiss() {
    if (this.closing) return;
    this.closing = true;
    closeOverlay(props().overlay);
  }

  close() {
    const overlay = props()?.overlay;
    if (!checking() && overlay) {
      if (shared(STATE)?.overlay === overlay) setShared(STATE, null);
      run(`pbogut-keys.closed-${overlay}`);
    }
  }

  onKey(event, cx) {
    cx.stop_propagation();
    if (event.keystroke === "escape") return this.dismiss();
    if (props()?.hints) {
      const state = shared(STATE);
      if (state?.overlay !== props().overlay) return;
      const { mode, hints, prefix } = state, key = event.keystroke;
      const targets = (shared(`pbogut.${mode}.hintTargets`) ?? []).filter(id => Object.hasOwn(hints, id));
      if (key === "j" || key === "k") {
        if (targets.length) {
          const i = targets.indexOf(state.selected);
          const at = i < 0 ? 0 : (i + (key === "j" ? 1 : -1) + targets.length) % targets.length;
          setShared(STATE, { ...state, prefix: "", selected: targets[at] });
        }
        return;
      }
      if (event.is_held) return;
      if (key === "enter") {
        if (targets.includes(state.selected)) this.choose(mode, state.selected);
        return;
      }
      if (key === (mode === "spaces" ? "alt-o" : "alt-i")) {
        run(`pbogut-keys.${mode}`);
        return;
      }
      if (key === "backspace") { setShared(STATE, { ...state, prefix: prefix.slice(0, -1) }); return; }
      if (key.length !== 1) return;
      const next = prefix + key;
      const match = Object.entries(hints).find(([, hint]) => hint === next);
      if (!match) {
        if (Object.values(hints).some(h => h.startsWith(next))) setShared(STATE, { ...state, prefix: next });
        return;
      }
      if (targets.includes(match[0])) this.choose(mode, match[0]);
      return;
    }
    const action = prefixBindings[event.keystroke];
    if (action) {
      this.dismiss();
      run(...action);
    }
  }

  choose(mode, id) {
    this.dismiss();
    if (mode === "spaces") {
      if (spaces().some(s => s.id === id)) run("space.select", { id });
    } else if (agents().some(a => a.address === id) || terminals().some(t => t.address === id && t.parent && t.state === "live")) {
      run("agent.focus", { terminal: id });
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
    const mode = props()?.mode, sidebar = Object.hasOwn(pickers, mode), space = mode === "spaces";
    const bar = h_flex().id("shortcuts").track_focus(this.handle).h(36)
      .overflow_hidden().on_key_down((event, cx) => this.onKey(event, cx))
      .on_key_up((event) => {
        if (sidebar && event.key === (space ? "o" : "i")) {
          run(`pbogut-keys.released-${props().overlay}`);
        }
      })
      .on_mouse_down("left", (_event, cx) => cx.stop_propagation())
      .on_mouse_down_out(() => this.dismiss())
      .items_center().px(12).gap(24).whitespace_nowrap()
      .bg(t.popover).border_t_1().border_color(t.border)
      .text_color(t.foreground).text_size(13)
      .when(sidebar, el => el.child(h_flex().flex_1().min_w(0).gap(24).overflow_hidden()
        .child(div().flex_shrink_0().font_semibold().text_color(t.accent).child(space ? "Space hints" : "Agent hints"))
        .child(Object.keys(props().hints).length
          ? h_flex().gap(8).items_center().child("Type a hint or").child(hint("j", "down"))
            .child(hint("k", "up")).child(hint("Enter", "select"))
          : "No visible targets"))
        .child(hint(space ? "Alt+O" : "Alt+I", "Open picker")))
      .when(!sidebar, el => el.child(h_flex().flex_1().min_w(0).gap(24).overflow_hidden()
        .child(hint("Ctrl+G", "send Ctrl+G"))
        .child(hint("v", "split right"))
        .child(hint("s", "split down"))
        .child(hint("c", "new tab"))
        .child(hint("q", "close tab"))
        .child(hint("x", "close project"))))
      .child(hint("Esc", "cancel"));
    // Native relative positioning follows resizes without reopening the overlay.
    return div().id("shortcuts-overlay").relative().size_full()
      .on_mouse_down("left", (_event, cx) => cx.stop_propagation())
      .child(bar.absolute().left(props()?.left ?? 0).right(0).bottom(props()?.bottom ?? 0));
  }
}
