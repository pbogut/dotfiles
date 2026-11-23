import { View, div } from "gpui-kit";
import { h_flex } from "gpui-base";
import { appHome, checking, closeOverlay, exec, focused, hc, notify, panes, props, run, settings, spaces, terminals, theme } from "herdr";
import { assignHints } from "./hints.js";
import { existingTargets, grid, visibleLinks } from "./links.js";
import { openCodeLinks } from "./opencode-wraps.js";
import { lazygitLinks } from "./lazygit-wraps.js";

export default class LinkHints extends View {
  init(_props, cx) {
    this.handle = cx.focus_handle();
    this.prefix = "";
    this.labels = [];
    if (checking()) return;
    this.handle.focus();
    this.terminal = props().terminal;
    const terminal = terminals().find((t) => t.address === this.terminal);
    if (!terminal?.cols || !terminal.rows) return this.dismiss();
    const { rows, cols } = terminal;
    const pane = panes().find((p) => p.terminal === this.terminal);
    this.space = spaces().find((s) => s.tabs.some((tab) => tab.id === pane?.tab));
    this.location = { cwd: pane?.cwd, on: this.space?.machine };
    const scanLinks = { opencode: openCodeLinks, lazygit: lazygitLinks }[pane?.program?.key] ?? visibleLinks;
    const scroll = pane?.scroll;
    const history = Math.max(0, (scroll?.total ?? rows) - rows);
    const top = scroll?.offset ?? 0;
    const { zoom, font_size } = settings();
    this.grid = grid(props().box, cols, rows, zoom, font_size);
    cx.spawn(async (cx) => {
      try {
        // Request the retained history: Core counts logical lines, but the
        // viewport offset counts physical (possibly soft-wrapped) rows.
        const result = await hc(["read", this.terminal, "--json", "--lines", String(history)]);
        if (this.closed) return;
        if (result.code !== 0) throw new Error(result.stderr.trim() || "Terminal read failed");
        const targets = scanLinks(JSON.parse(result.stdout).text, cols, top, rows,
          Boolean(this.space && this.location.cwd));
        const links = await existingTargets(targets, exec, this.location);
        if (this.closed) return;
        if (!links.length) {
          notify({ title: "No visible URLs or files", level: "info", timeout: 1500 });
          return this.dismiss();
        }
        const hints = assignHints(links.map((_, i) => String(i)));
        this.labels = links.map((link, i) => ({ ...link, key: hints[i] }));
        cx.notify();
      } catch (error) {
        if (this.closed) return;
        notify({ title: "Could not show link hints", body: String(error.message ?? error), level: "error" });
        this.dismiss();
      }
    });
    const size = window.viewport_size();
    cx.timer.every(100, () => {
      if (this.closed) return;
      const cur = terminals().find((t) => t.address === this.terminal);
      const view = panes().find((p) => p.terminal === this.terminal)?.scroll;
      const now = window.viewport_size();
      if (!this.handle.is_focused() || !window.is_window_active() || focused()?.terminal !== this.terminal ||
          cur?.rows !== rows || cur?.cols !== cols || view?.offset !== scroll?.offset ||
          view?.total !== scroll?.total || settings().zoom !== zoom ||
          now.width !== size.width || now.height !== size.height) this.dismiss();
    });
  }

  dismiss() {
    if (!this.closed) closeOverlay(props().overlay);
    this.closed = true;
  }

  close() {
    this.closed = true;
    if (!checking()) run(`pbogut-keys.closed-${props().overlay}`);
  }

  openFile(hit, cx) {
    const { id, machine } = this.space;
    const spaceId = machine && id.startsWith(`${machine}/`) ? id.slice(machine.length + 1) : id;
    const args = [
      ...(!machine ? [`HERDR_APP_HOME=${appHome()}`] : []),
      `HERDR_APP_SPACE_ID=${spaceId}`, "herdr-app-vim",
      ...(hit.line ? ["--line", String(hit.line)] : []), "--", hit.path,
    ];
    cx.spawn(async () => {
      try {
        const result = await exec("env", args, this.location);
        if (result.code !== 0) throw new Error(result.stderr.trim() || hit.path);
      } catch (error) {
        notify({ title: "Could not open file in Neovim", body: String(error.message ?? error), level: "error" });
      }
    });
  }

  render() {
    const t = theme(), g = this.grid;
    return div().id("terminal-link-hints").relative().size_full().track_focus(this.handle)
      .on_mouse_down("left", (_e, cx) => { cx.stop_propagation(); this.dismiss(); })
      .on_scroll_wheel((_e, cx) => { cx.stop_propagation(); this.dismiss(); })
      .on_key_down((e, cx) => {
        cx.stop_propagation();
        const k = e.keystroke;
        if (k === "escape") return this.dismiss();
        if (e.is_held) return;
        if (k === "backspace") this.prefix = this.prefix.slice(0, -1);
        else if (k.length === 1 && this.labels.some((l) => l.key.startsWith(this.prefix + k))) {
          this.prefix += k;
          const hit = this.labels.find((l) => l.key === this.prefix);
          if (hit) {
            if (hit.path) this.openFile(hit, cx);
            else cx.open_url(hit.url);
            this.dismiss();
            return;
          }
        }
        cx.notify();
      })
      .children(this.labels.filter((l) => l.key.startsWith(this.prefix)).map((l) =>
        h_flex().absolute().left(g.left + l.col * g.w).top(g.top + l.row * g.h + 1)
          .h(g.h - 2).px(3).items_center().justify_center().whitespace_nowrap()
          .rounded(3).border_1().border_color(t.accent).bg(t.surface)
          .font_family("JetBrainsMono Nerd Font Mono").text_size(Math.min(13, g.h * 0.62)).font_bold()
          .text_color(t.accent).child(l.key.toUpperCase())
      ));
  }
}
