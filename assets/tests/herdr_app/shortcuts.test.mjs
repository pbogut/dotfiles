import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";
import vm from "node:vm";

const root = new URL("../../../dot_config/herdr-app/mods/pbogut-keys/", import.meta.url);

async function fixture(name = "pbogut-keys", checking = false, overlay = true, exec = async () => ({ code: 0 })) {
  const calls = [];
  const tasks = [];
  const terminal = { address: "test/t1", rows: 24, cols: 80, selection: null };
  const focus = { pane: "test-pane", terminal: terminal.address };
  const config = { zoom: 1 };
  const pane = { terminal: terminal.address, scroll: null };
  let readTerminal = async () => ({ code: 0, stdout: JSON.stringify({ text: "", complete: true }) });
  const layout = JSON.parse(await readFile(new URL("../../layouts/pbogut.json", root), "utf8"));
  const context = vm.createContext({
    window: { viewport_size: () => ({ width: 1280, height: 800 }) },
  });
  const element = new Proxy({}, { get: () => () => element });
  let view;
  let resolveCommand;
  const commands = [];
  const shared = new Map();
  function sendCommand(command) {
    if (resolveCommand) {
      const resolve = resolveCommand;
      resolveCommand = null;
      resolve(command);
    } else commands.push(command);
  }
  const host = {
    window: () => ({ active: true }),
    shared: key => shared.get(key),
    setShared: (key, value) => shared.set(key, value),
    agents: () => [],
    spaces: () => [],
    appHome: () => "/app",
    checking: () => checking,
    closeOverlay: () => { calls.push(["close"]); view.close?.(); },
    focused: () => focus,
    panes: () => [pane],
    hc: async (args) => { calls.push(["hc", args]); return readTerminal(args); },
    exec: async (command, args, options) => { calls.push(["exec", command, ...args]); return exec(command, args, options); },
    nextCommand: () => commands.length ? Promise.resolve(commands.shift())
      : new Promise((resolve) => { resolveCommand = resolve; }),
    notify: (args) => calls.push(["notify", args]),
    layout: () => layout,
    openOverlay: (spec) => { calls.push(["open", spec]); return `${spec.mod}-overlay`; },
    props: () => overlay ? { overlay: "test-overlay" } : null,
    settings: () => config,
    run: (name, args) => {
      calls.push([name, args]);
      if (name === "pbogut-copy.selection-ready") sendCommand("selection-ready");
      if (name === "terminal.select") {
        const at = args.at === "cursor" ? { row: 10, col: 5 } : args.at;
        terminal.selection = { start: { ...at }, end: { ...at } };
      }
      if (name === "terminal.clear_selection") terminal.selection = null;
      if (name === "terminal.adjust_selection") {
        const end = terminal.selection.end;
        const lastRow = (pane.scroll?.total ?? terminal.rows) - 1;
        const direction = args.direction;
        if (direction === "line_end") end.col = terminal.cols - 1;
        else if (direction === "line_start") end.col = 0;
        else if (direction === "left" || direction === "right") {
          const cell = Math.max(0, Math.min((lastRow + 1) * terminal.cols - 1,
            end.row * terminal.cols + end.col + (direction === "left" ? -1 : 1)));
          end.row = Math.floor(cell / terminal.cols);
          end.col = cell % terminal.cols;
        } else {
          const step = { up: -1, down: 1, page_up: -terminal.rows, page_down: terminal.rows }[direction];
          end.row = Math.max(0, Math.min(lastRow, end.row + step));
        }
      }
    },
    terminals: () => [terminal],
    theme: () => ({}),
  };
  function mock(values) {
    return new vm.SyntheticModule(Object.keys(values), function () {
      for (const [key, value] of Object.entries(values)) this.setExport(key, value);
    }, { context });
  }
  const modules = {
    herdr: mock(host),
    "gpui-kit": mock({ View: class {}, div: () => element }),
    "gpui-base": mock({ v_flex: () => element, h_flex: () => element }),
    "./bindings.js": new vm.SourceTextModule(await readFile(new URL("bindings.js", root), "utf8"), { context }),
    "./words.js": new vm.SourceTextModule(await readFile(new URL("../pbogut-copy/words.js", root), "utf8"), { context }),
  };
  const main = new vm.SourceTextModule(await readFile(new URL(`../${name}/main.js`, root), "utf8"), { context });
  await main.link((name) => {
    assert.ok(modules[name], `Unexpected import: ${name}`);
    return modules[name];
  });
  await main.evaluate();
  const cx = {
    focus_handle: () => ({ focus: () => calls.push(["focus"]) }),
    stop_propagation() {},
    notify() {},
    timer: { after: (_delay, callback) => callback(cx) },
    spawn: (callback) => { tasks.push(callback(cx)); },
  };
  view = new main.namespace.default();
  view.init({}, cx);
  await new Promise(setImmediate);
  calls.length = 0;
  tasks.length = 0;
  return {
    view, terminal, pane, focus, config, calls, tasks,
    command: async (command) => {
      sendCommand(command);
      await new Promise(setImmediate);
    },
    key: (keystroke) => view.onKey({ keystroke }, cx),
    settle: () => new Promise(setImmediate),
    setChecking: (value) => { checking = value; },
    readTerminal: (read) => { readTerminal = read; },
  };
}

test("prefix closes the native overlay before running each action", async () => {
  for (const [key, command, direction] of [
    ["c", "tab.new", undefined], ["v", "pane.split", "right"], ["s", "pane.split", "down"],
    ["q", "tab.close", undefined], ["x", "pbogut-tabs.close-project", undefined],
  ]) {
    const app = await fixture();
    app.key(key);
    assert.deepEqual(app.calls.map(([name]) => name),
      ["close", "pbogut-keys.closed-test-overlay", command]);
    assert.equal(app.calls[2][1]?.direction, direction);
  }
});

test("removed prefix shortcuts do nothing, including navigation, copy, and numbers", async () => {
  const app = await fixture();
  for (const key of [
    "shift-s", "y", "ctrl-y", "ctrl-k", "w", "ctrl-w", "b", "t", "ctrl-t",
    "p", "n", "]", "[", "ctrl-shift-d", "h", "j", "k", "l", "shift-x",
    "z", "shift-n", "shift-w", "shift-t", "?", "shift-/", "g", "ctrl-j",
    "tab", "shift-tab", "up", "down", "left", "right", "ctrl-c",
    "ctrl-g", "enter", ..."123456789",
  ]) app.key(key);
  assert.deepEqual(app.calls, []);
  app.key("escape");
  assert.deepEqual(app.calls.map(([name]) => name), ["close", "pbogut-keys.closed-test-overlay"]);
});

test("the prefix overlay closes before a second Ctrl+G sends the key to the focused terminal", async () => {
  const app = await fixture("pbogut-keys", false, false);
  for (const zoom of [1, 1.1]) {
    app.config.zoom = zoom;
    app.view.width = 1280 - 269 * zoom;
    await app.command("toggle");
    const [name, spec] = app.calls.at(-1);
    assert.equal(name, "open");
    assert.equal(spec.frame, "none");
    assert.equal(spec.width, 1, "The native overlay must follow the viewport width");
    assert.equal(spec.height, 1, "The native overlay must follow the viewport height");
    assert.equal(spec.at.x, 0);
    assert.equal(spec.at.y, 0);
    assert.ok(Math.abs(spec.props.left - 269) < 0.001);
    assert.equal(spec.props.bottom, 28, "The menu covers the tabs above the status bar");
    const overlay = app.view.overlay;
    await app.command("toggle");
    assert.deepEqual(app.calls.slice(-2), [
      ["close"], ["exec", "node", "/app/mods/pbogut-keys/send-ctrl-g.mjs", "test/t1", "hc"],
    ]);
    await app.command(`closed-${overlay}`);
    assert.equal(app.view.overlay, null);
  }
  assert.ok(app.calls.every(([name]) => ["open", "close", "exec"].includes(name)));
});

test("pending Ctrl+G delivery never blocks repeated prefixes or copy mode", async () => {
  const pending = [];
  const app = await fixture("pbogut-keys", false, false, () => new Promise(resolve => pending.push(resolve)));
  app.view.width = 1011;
  for (let i = 0; i < 4; i++) {
    await app.command("toggle");
    assert.ok(app.view.overlay);
    await app.command("toggle");
    assert.equal(app.view.overlay, null);
  }
  assert.equal(pending.length, 4);
  await app.command("copy");
  assert.equal(app.calls.at(-1)[1].mod, "pbogut-copy");
  app.focus.terminal = "another/t2";
  pending[0]({ code: 1, stderr: "Connection lost" });
  for (const resolve of pending.slice(1)) resolve({ code: 0 });
  await Promise.all(app.tasks);
  assert.equal(app.calls.filter(([name]) => name === "exec").length, 4, "Failed delivery is never retried");
  assert.ok(app.calls.filter(([name]) => name === "exec").every(call => call[3] === "test/t1"));
  assert.equal(app.calls.at(-1)[1].body, "Connection lost");
});

test("copy mode uses the bottom overlay and replaces prefix mode without stale cleanup closing it", async () => {
  const app = await fixture("pbogut-keys", false, false);
  app.view.width = 1011;
  await app.command("toggle");
  const prefix = app.view.overlay;
  await app.command("copy");
  assert.equal(app.calls.at(-2)[0], "close");
  const [name, spec] = app.calls.at(-1);
  assert.equal(name, "open");
  assert.equal(spec.mod, "pbogut-copy");
  assert.equal(spec.height, 1);
  assert.equal(spec.width, 1);
  assert.equal(spec.frame, "none");
  assert.equal(spec.props.bottom, 28, "Copy mode also covers the tabs");
  const copy = app.view.overlay;
  await app.command(`closed-${prefix}`);
  assert.equal(app.view.overlay, copy, "Late prefix cleanup must not forget the open copy overlay");
  await app.command("copy");
  assert.equal(app.calls.at(-1)[0], "close");
  await app.command(`closed-${copy}`);
  assert.equal(app.view.overlay, null);
  assert.ok(app.calls.every(([name]) => name !== "exec"), "Switching to copy mode and toggling it off sends no key");
});

test("copy cursor moves without extending a range until selection starts", async () => {
  const app = await fixture("pbogut-copy");
  app.key("h");
  app.view.render();
  assert.deepEqual(app.terminal.selection.start, { row: 10, col: 4 });
  assert.deepEqual(app.terminal.selection.start, app.terminal.selection.end);
  assert.ok(app.calls.every(([name]) => name !== "terminal.adjust_selection"));
  await app.settle();
  assert.deepEqual(app.terminal.selection.start, { row: 10, col: 4 });
  app.key("v");
  await app.settle();
  app.key("l");
  app.terminal.selection.end = { row: 10, col: 8 };
  await app.settle();
  assert.deepEqual(app.terminal.selection.start, { row: 10, col: 4 });
  app.key("y");
  assert.deepEqual(app.calls.slice(-5).map(([name]) => name),
    ["terminal.copy", "close", "terminal.clear_selection", "terminal.scroll", "pbogut-keys.closed-test-overlay"]);
  assert.equal(app.terminal.selection, null);
});

test("Escape cleans up copy mode, including when the host closes the overlay", async () => {
  const app = await fixture("pbogut-copy");
  app.view.close();
  assert.equal(app.terminal.selection, null);
  assert.equal(app.calls.find(([name]) => name === "terminal.scroll")[1].terminal, "test/t1");
});

test("queued word motions use fresh text and preserve the visual selection anchor", async () => {
  const app = await fixture("pbogut-copy");
  app.terminal.selection = { start: { row: 0, col: 0 }, end: { row: 0, col: 0 } };
  app.readTerminal(async () => ({ code: 0, stdout: JSON.stringify({ text: "one two... three", complete: true }) }));
  for (const key of ["w", "v", "e", "e"]) app.key(key);
  await app.settle();
  assert.deepEqual(app.terminal.selection, { start: { row: 0, col: 4 }, end: { row: 0, col: 9 } });
  app.key("b");
  await app.settle();
  assert.deepEqual(app.terminal.selection, { start: { row: 0, col: 4 }, end: { row: 0, col: 7 } });
  assert.equal(app.calls.filter(([name]) => name === "hc").length, 4);
  app.key("v");
  app.key("b");
  await app.settle();
  assert.deepEqual(app.terminal.selection, { start: { row: 0, col: 4 }, end: { row: 0, col: 4 } });
});

test("incomplete older history still supports word movement in retained rows", async () => {
  const app = await fixture("pbogut-copy");
  app.pane.scroll = { total: 50, len: 24, offset: 26 };
  app.terminal.selection = { start: { row: 26, col: 0 }, end: { row: 26, col: 0 } };
  app.readTerminal(async (args) => {
    assert.deepEqual([...args], ["read", "test/t1", "--json", "--lines", "26"]);
    return { code: 0, stdout: JSON.stringify({ text: Array(50).fill("one two").join("\n"), complete: false, how: "history" }) };
  });
  app.key("b");
  await app.settle();
  assert.deepEqual(app.terminal.selection, { start: { row: 25, col: 4 }, end: { row: 25, col: 4 } });
  assert.equal(app.calls.find(([name]) => name === "terminal.scroll")[1].lines, -1);
  assert.ok(app.calls.every(([name]) => name !== "terminal.adjust_selection"));
  for (const key of ["v", "e", "y"]) app.key(key);
  await app.settle();
  assert.ok(app.calls.some(([name]) => name === "terminal.copy"));
  assert.ok(app.calls.every(([name]) => name !== "notify"));
});

test("whole-line selections ignore word motions like other horizontal motions", async () => {
  const app = await fixture("pbogut-copy");
  app.key("shift-v");
  await app.settle();
  const before = structuredClone(app.terminal.selection);
  app.calls.length = 0;
  for (const key of ["w", "e", "b", "shift-w", "shift-e", "shift-b", "^", "shift-6"]) app.key(key);
  assert.deepEqual(app.terminal.selection, before);
  assert.deepEqual(app.calls, []);
});

test("closing during a word read discards pending motion and copy", async () => {
  for (const close of [(app) => app.key("escape"), (app) => app.view.close()]) {
    const app = await fixture("pbogut-copy");
    let finish;
    app.readTerminal(() => new Promise((resolve) => { finish = resolve; }));
    app.key("w");
    app.key("y");
    close(app);
    const count = app.calls.length;
    finish({ code: 0, stdout: JSON.stringify({ text: "one two", complete: true }) });
    await app.settle();
    assert.equal(app.calls.length, count);
    assert.equal(app.terminal.selection, null);
  }
});

test("caret and shifted word keys share the selection queue", async () => {
  for (const caret of ["^", "shift-6"]) {
    const app = await fixture("pbogut-copy");
    app.terminal.selection = { start: { row: 0, col: 0 }, end: { row: 0, col: 0 } };
    app.readTerminal(async () => ({
      code: 0, stdout: JSON.stringify({ text: "  src/foo.js  https://a.b/x?q=1", complete: true }),
    }));
    for (const key of [caret, "v", "shift-E"]) app.key(key);
    await app.settle();
    assert.deepEqual(app.terminal.selection, { start: { row: 0, col: 2 }, end: { row: 0, col: 11 } });
    for (const key of ["v", "shift-w", "v", "shift-e", "shift-b", "shift-b"]) app.key(key);
    await app.settle();
    assert.deepEqual(app.terminal.selection, { start: { row: 0, col: 14 }, end: { row: 0, col: 2 } });
  }
});

test("half-page motions preserve columns, extend v, and clamp at history boundaries", async () => {
  for (const rows of [24, 25, 1]) {
    const app = await fixture("pbogut-copy");
    app.terminal.rows = rows;
    app.pane.scroll = { total: 80, len: rows, offset: 0 };
    const half = Math.max(1, Math.floor(rows / 2));
    app.key("ctrl-d");
    await app.settle();
    assert.deepEqual(app.terminal.selection, { start: { row: 10 + half, col: 5 }, end: { row: 10 + half, col: 5 } });
    assert.ok(app.calls.every(([name]) => name !== "terminal.adjust_selection"));
    for (const key of ["ctrl-u", "v", "ctrl-d"]) app.key(key);
    await app.settle();
    assert.deepEqual(app.terminal.selection, { start: { row: 10, col: 5 }, end: { row: 10 + half, col: 5 } });
    app.key("ctrl-u");
    await app.settle();
    assert.deepEqual(app.terminal.selection, { start: { row: 10, col: 5 }, end: { row: 10, col: 5 } });
    app.key("v");
    await app.settle();
    for (const [row, key, expected] of [[0, "ctrl-u", 0], [79, "ctrl-d", 79]]) {
      app.terminal.selection = { start: { row, col: 5 }, end: { row, col: 5 } };
      app.key(key);
      await app.settle();
      assert.deepEqual(app.terminal.selection, { start: { row: expected, col: 5 }, end: { row: expected, col: 5 } });
    }
  }
});

test("half-page line selections stay whole when reversing across the anchor", async () => {
  const app = await fixture("pbogut-copy");
  app.pane.scroll = { total: 80, len: 24, offset: 0 };
  app.terminal.selection = { start: { row: 20, col: 5 }, end: { row: 20, col: 5 } };
  for (const key of ["shift-v", "ctrl-d"]) app.key(key);
  await app.settle();
  assert.deepEqual(app.terminal.selection, { start: { row: 20, col: 0 }, end: { row: 32, col: 79 } });
  for (const key of ["ctrl-u", "ctrl-u"]) app.key(key);
  await app.settle();
  assert.deepEqual(app.terminal.selection, { start: { row: 20, col: 79 }, end: { row: 8, col: 0 } });
  for (const key of ["ctrl-d", "ctrl-d"]) app.key(key);
  await app.settle();
  assert.deepEqual(app.terminal.selection, { start: { row: 20, col: 0 }, end: { row: 32, col: 79 } });
});

test("failed word reads report the error, discard queued copy, and release the key queue", async () => {
  const app = await fixture("pbogut-copy");
  app.readTerminal(async () => { throw new Error("Disconnected"); });
  app.key("w");
  app.key("y");
  await app.settle();
  assert.equal(app.calls.at(-1)[1].body, "Disconnected");
  assert.ok(app.calls.every(([name]) => name !== "terminal.copy"));
  app.key("h");
  await app.settle();
  assert.equal(app.terminal.selection.end.col, 4);
});

test("resizing during a word read retries against the new grid", async () => {
  const app = await fixture("pbogut-copy");
  app.terminal.selection = { start: { row: 0, col: 0 }, end: { row: 0, col: 0 } };
  let reads = 0;
  app.readTerminal(async () => {
    if (++reads === 1) app.terminal.cols = 5;
    return { code: 0, stdout: JSON.stringify({ text: "abcdef gh", complete: true }) };
  });
  app.key("e");
  await app.settle();
  assert.equal(reads, 2);
  assert.deepEqual(app.terminal.selection, { start: { row: 1, col: 0 }, end: { row: 1, col: 0 } });
});

test("closing during movement discards pending selection and copy actions", async () => {
  for (const close of [(app) => app.key("escape"), (app) => app.view.close()]) {
    const app = await fixture("pbogut-copy");
    app.key("h");
    app.key("y");
    close(app);
    const count = app.calls.length;
    await app.settle();
    assert.equal(app.calls.length, count);
    assert.equal(app.terminal.selection, null);
    assert.ok(app.calls.every(([name]) => name !== "terminal.copy"));
  }
});

test("checking a mod never changes the terminal on cleanup", async () => {
  const app = await fixture("pbogut-copy", true);
  assert.equal(app.terminal.selection, null, "Check must not start a selection");
  app.view.close();
  assert.deepEqual(app.calls, []);
});

test("Alt+Esc and Ctrl+G use the same bottom overlay controller", async () => {
  const keys = JSON.parse(await readFile(new URL("../../keys.json", root), "utf8"));
  assert.equal(keys.global["alt-escape"], "pbogut-keys.copy");
  assert.equal(keys.global["ctrl-g"], "pbogut-keys.toggle");
  assert.equal(keys["mod:pbogut-keys"], undefined);
});
