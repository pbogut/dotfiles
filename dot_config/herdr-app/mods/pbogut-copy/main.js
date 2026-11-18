import { View, div } from "gpui-kit";
import { h_flex } from "gpui-base";
import { checking, closeOverlay, focused, hc, nextCommand, notify, panes, props, run, terminals, theme } from "herdr";
import { wordTarget } from "./words.js";

const directions = {
  h: "left",
  j: "down",
  k: "up",
  l: "right",
  "ctrl-b": "page_up",
  "ctrl-f": "page_down",
  home: "home", "shift-g": "end", end: "end",
  "0": "line_start", "$": "line_end", "shift-4": "line_end",
};

export default class CopyMode extends View {
  init(_props, cx) {
    this.handle = cx.focus_handle();
    this.terminal = focused()?.terminal;
    this.selecting = false;
    this.lineAnchor = null;
    this.keys = [];
    this.waiting = false;
    if (checking()) return;
    if (!this.terminal) return this.dismiss();
    this.handle.focus();
    cx.spawn(async (cx) => {
      for (;;) {
        if (await nextCommand() !== "selection-ready") continue;
        if (this.closed) return;
        this.waiting = false;
        this.drainKeys(cx);
      }
    });
    run("terminal.select", { terminal: this.terminal, at: "cursor" });
    this.waitForSelection();
  }

  dismiss() {
    this.closed = true;
    this.keys = [];
    closeOverlay(props().overlay);
  }

  close() {
    this.closed = true;
    this.keys = [];
    if (checking()) return;
    if (this.terminal) {
      run("terminal.clear_selection", { terminal: this.terminal });
      run("terminal.scroll", { terminal: this.terminal, to: "bottom" });
    }
    if (props()?.overlay) run(`pbogut-keys.closed-${props().overlay}`);
  }

  selection() {
    return terminals().find((terminal) => terminal.address === this.terminal)?.selection;
  }

  waitForSelection() {
    // This command returns after earlier native selection commands are applied.
    this.waiting = true;
    run("pbogut-copy.selection-ready");
  }

  drainKeys(cx) {
    while (!this.closed && !this.waiting && this.keys.length) {
      this.handleKey(this.keys.shift(), cx);
    }
  }

  moveCursor(direction) {
    const terminal = terminals().find((terminal) => terminal.address === this.terminal);
    if (!terminal?.selection) return;
    const scroll = panes().find((pane) => pane.terminal === this.terminal)?.scroll;
    const lastRow = (scroll?.total ?? terminal.rows) - 1;
    const lastCol = terminal.cols - 1;
    let { row, col } = terminal.selection.end;
    if (direction === "left" || direction === "right") {
      const cell = Math.max(0, Math.min((lastRow + 1) * terminal.cols - 1,
        row * terminal.cols + col + (direction === "left" ? -1 : 1)));
      row = Math.floor(cell / terminal.cols);
      col = cell % terminal.cols;
    } else if (direction === "home" || direction === "end") {
      row = direction === "home" ? 0 : lastRow;
      col = direction === "home" ? 0 : lastCol;
    } else if (direction === "line_start" || direction === "line_end") {
      col = direction === "line_start" ? 0 : lastCol;
    } else {
      const step = { up: -1, down: 1, page_up: -terminal.rows, page_down: terminal.rows }[direction];
      row = Math.max(0, Math.min(lastRow, row + step));
    }
    this.selectCursor({ row, col }, scroll);
  }

  selectCursor({ row, col }, scroll) {
    // Replace the single cell directly so no intermediate range can be painted.
    run("terminal.select", { terminal: this.terminal, at: { row, col } });
    if (scroll) {
      const offset = Math.max(row - scroll.len + 1, Math.min(scroll.offset, row));
      if (offset !== scroll.offset) {
        run("terminal.scroll", { terminal: this.terminal, lines: offset - scroll.offset });
      }
    }
  }

  moveWord(key, cx) {
    const terminal = terminals().find((terminal) => terminal.address === this.terminal);
    if (!terminal?.selection) return;
    const scroll = panes().find((pane) => pane.terminal === this.terminal)?.scroll;
    const total = scroll?.total ?? terminal.rows;
    const { rows, cols } = terminal;
    this.waiting = true;
    cx.spawn(async (cx) => {
      let moved = false;
      try {
        const result = await hc(["read", this.terminal, "--json", "--lines", String(Math.max(0, total - rows))]);
        if (this.closed) return;
        if (result.code !== 0) throw new Error(result.stderr.trim() || "Could not read terminal text.");
        const content = JSON.parse(result.stdout);
        if (!content.complete) throw new Error("Terminal text is incomplete.");
        const current = terminals().find((terminal) => terminal.address === this.terminal);
        const view = panes().find((pane) => pane.terminal === this.terminal)?.scroll;
        if (!current?.selection) return;
        if (current.cols !== cols || current.rows !== rows || (view?.total ?? rows) !== total) {
          this.keys.unshift(key);
          return;
        }
        const from = { ...current.selection.end };
        const at = wordTarget(content.text, cols, total, from, key);
        if (this.selecting) {
          const adjust = (direction) => run("terminal.adjust_selection", { terminal: this.terminal, direction });
          const distance = Math.abs(at.row - from.row);
          for (let i = 0; i < Math.floor(distance / rows); i++) adjust(at.row < from.row ? "page_up" : "page_down");
          for (let i = 0; i < distance % rows; i++) adjust(at.row < from.row ? "up" : "down");
          for (let i = 0; i < Math.abs(at.col - from.col); i++) adjust(at.col < from.col ? "left" : "right");
        } else this.selectCursor(at, view);
        moved = true;
        this.waitForSelection();
      } catch (error) {
        if (!this.closed) {
          this.keys = [];
          notify({ title: "Could not move by word", body: String(error.message ?? error), level: "error" });
        }
      } finally {
        if (!moved) this.waiting = false;
        if (!this.closed) {
          this.drainKeys(cx);
          cx.notify();
        }
      }
    });
  }

  moveLines(direction) {
    const terminal = terminals().find((terminal) => terminal.address === this.terminal);
    if (!terminal?.selection) return;
    const adjust = (direction) => run("terminal.adjust_selection", { terminal: this.terminal, direction });
    const anchor = (side) => run("terminal.select", {
      terminal: this.terminal,
      at: { row: this.lineAnchor, col: side < 0 ? terminal.cols - 1 : 0 },
    });
    if (direction === "home" || direction === "end") {
      this.lineDirection = direction === "home" ? -1 : 1;
      anchor(this.lineDirection);
      adjust(direction);
    } else {
      const step = { up: -1, down: 1, page_up: -1, page_down: 1 }[direction];
      // Horizontal motions cannot turn a whole-line selection into a partial one.
      if (!step) return;
      const row = terminal.selection.end.row;
      const target = Math.max(0, row + step * (direction.startsWith("page_") ? terminal.rows : 1));
      const side = Math.sign(target - this.lineAnchor) || this.lineDirection;
      let count = Math.abs(target - row);
      if (side !== this.lineDirection) {
        anchor(side);
        count = Math.abs(target - this.lineAnchor);
      }
      this.lineDirection = side;
      // Paging stays bounded by one viewport, even when it crosses the anchor.
      for (let i = 0; i < count; i++) adjust(step < 0 ? "up" : "down");
    }
    adjust(this.lineDirection < 0 ? "line_start" : "line_end");
    return true;
  }

  onKey(event, cx) {
    cx.stop_propagation();
    const key = event.keystroke.replace(/([A-Z])$/, (letter) => letter.toLowerCase());
    if (["escape", "ctrl-c"].includes(key)) return this.dismiss();
    this.keys.push(key);
    this.drainKeys(cx);
  }

  handleKey(key, cx) {
    if (key === "y") {
      run("terminal.copy");
      return this.dismiss();
    }
    if (key === "v" || key === "shift-v") {
      const at = this.selection()?.end;
      this.selecting = key === "shift-v" || !this.selecting;
      this.lineAnchor = key === "shift-v" ? at?.row ?? null : null;
      this.lineDirection = 1;
      if (at) {
        // Native line mode skips indentation; anchor full lines at column zero.
        run("terminal.select", {
          terminal: this.terminal, at: this.lineAnchor === null ? at : { row: at.row, col: 0 },
        });
        if (this.lineAnchor !== null) {
          run("terminal.adjust_selection", { terminal: this.terminal, direction: "line_end" });
        }
        this.waitForSelection();
      }
      cx.notify();
      return;
    }
    const direction = key === "g" && this.lastKey === "g" ? "home" : directions[key];
    this.lastKey = key;
    if (["w", "e", "b"].includes(key)) {
      if (this.lineAnchor === null) this.moveWord(key, cx);
      return;
    }
    if (!direction) return;
    if (this.lineAnchor !== null) {
      if (this.moveLines(direction)) this.waitForSelection();
      cx.notify();
      return;
    }
    if (this.selecting) run("terminal.adjust_selection", { terminal: this.terminal, direction });
    else this.moveCursor(direction);
    this.waitForSelection();
    cx.notify();
  }

  render() {
    const t = theme();
    const keycap = (key) => h_flex().h(22).min_w(22).px(5).justify_center()
      .border_1().rounded(4).border_color(t.border).bg(t.surface)
      .text_color(t.accent).text_size(12).child(key);
    const hint = (keys, label) => h_flex().gap(6).flex_shrink_0()
      .child(h_flex().gap(4).children(keys.map(keycap)))
      .child(div().child(label));
    const bar = h_flex().id("copy-mode").track_focus(this.handle).h(36)
      .px(12).gap(24).overflow_hidden().whitespace_nowrap()
      .bg(t.popover).border_t_1().border_color(t.border)
      .text_color(t.foreground).text_size(13)
      .on_key_down((event, cx) => this.onKey(event, cx))
      .on_mouse_down("left", (_event, cx) => cx.stop_propagation())
      .on_mouse_down_out(() => this.dismiss())
      .child(h_flex().flex_1().min_w(0).gap(24).overflow_hidden()
        .child(div().flex_shrink_0().font_semibold().text_color(t.accent)
          .child(this.selecting ? "Copy · selecting" : "Copy mode"))
        .child(hint(["hjkl"], "move"))
        .child(hint(["w", "e", "b"], "words"))
        .child(hint(["v"], "select"))
        .child(hint(["V"], "lines"))
        .child(hint(["0", "$"], "line edges"))
        .child(hint(["gg", "G"], "history edges"))
        .child(hint(["Ctrl+B"], "page up"))
        .child(hint(["Ctrl+F"], "page down")))
      .child(h_flex().flex_shrink_0().gap(24)
        .child(hint(["y"], "copy"))
        .child(hint(["Esc"], "cancel")));
    return div().id("copy-overlay").relative().size_full()
      .on_mouse_down("left", (_event, cx) => cx.stop_propagation())
      .child(bar.absolute().left(props()?.left ?? 0).right(0).bottom(props()?.bottom ?? 0));
  }
}
