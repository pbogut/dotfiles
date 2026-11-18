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
  const layout = JSON.parse(await readFile(new URL("../../layouts/pbogut.json", root), "utf8"));
  const context = vm.createContext({
    window: { viewport_size: () => ({ width: 1280, height: 800 }) },
  });
  const element = new Proxy({}, { get: () => () => element });
  let view;
  let resolveCommand;
  const commands = [];
  function sendCommand(command) {
    if (resolveCommand) {
      const resolve = resolveCommand;
      resolveCommand = null;
      resolve(command);
    } else commands.push(command);
  }
  const host = {
    appHome: () => "/app",
    checking: () => checking,
    closeOverlay: () => { calls.push(["close"]); view.close?.(); },
    focused: () => focus,
    panes: () => [{ terminal: terminal.address, scroll: null }],
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
    view, terminal, focus, config, calls, tasks,
    command: async (command) => {
      sendCommand(command);
      await new Promise(setImmediate);
    },
    key: (keystroke) => view.onKey({ keystroke }, cx),
    settle: () => new Promise(setImmediate),
    setChecking: (value) => { checking = value; },
  };
}

test("prefix closes the native overlay before running each action", async () => {
  for (const [key, command, direction] of [
    ["c", "tab.new", undefined], ["v", "pane.split", "right"], ["s", "pane.split", "down"],
    ["x", "pbogut-tabs.close-project", undefined],
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
    "tab", "shift-tab", "up", "down", "left", "right", "q", "ctrl-c",
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
