import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";
import vm from "node:vm";

const root = new URL("../../../dot_config/herdr-app/mods/pbogut-keys/", import.meta.url);

async function fixture(name = "pbogut-keys", checking = false, overlay = true) {
  const calls = [];
  const tasks = [];
  const terminal = { address: "test/t1", selection: null };
  const focus = { pane: "test-pane", terminal: terminal.address };
  const config = { zoom: 1 };
  const context = vm.createContext({
    window: { viewport_size: () => ({ width: 1280, height: 800 }) },
  });
  const element = new Proxy({}, { get: () => () => element });
  let view;
  let resolveCommand;
  const host = {
    checking: () => checking,
    closeOverlay: () => { calls.push(["close"]); view.close?.(); },
    focused: () => focus,
    hc: async (args) => { calls.push(["hc", ...args]); return { code: 0 }; },
    nextCommand: () => new Promise((resolve) => { resolveCommand = resolve; }),
    notify: (args) => calls.push(["notify", args]),
    layout: () => ({
      children: [{ id: "work", children: [
        { id: "main" }, { id: "prefix-anchor" },
        { id: "tabs", size: { px: 42 } }, { id: "status", size: { px: 28 } },
      ] }],
    }),
    openOverlay: (spec) => { calls.push(["open", spec]); return "test-overlay"; },
    props: () => overlay ? { overlay: "test-overlay" } : null,
    settings: () => config,
    run: (name, args) => {
      calls.push([name, args]);
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
  calls.length = 0;
  tasks.length = 0;
  return {
    view, terminal, focus, config, calls, tasks,
    command: async (command) => {
      resolveCommand(command);
      await new Promise(setImmediate);
    },
    key: (keystroke) => view.onKey({ keystroke }, cx),
    setChecking: (value) => { checking = value; },
  };
}

test("prefix closes the native overlay before running each action", async () => {
  for (const [key, command, direction] of [
    ["c", "tab.new", undefined], ["v", "pane.split", "right"], ["s", "pane.split", "down"],
  ]) {
    const app = await fixture();
    app.key(key);
    assert.deepEqual(app.calls.map(([name]) => name),
      ["close", "pbogut-keys.closed-test-overlay", command]);
    assert.equal(app.calls[2][1]?.direction, direction);
  }
});

test("removed prefix shortcuts do nothing, including navigation, copy, closing, and numbers", async () => {
  const app = await fixture();
  for (const key of [
    "shift-s", "y", "ctrl-y", "ctrl-k", "w", "ctrl-w", "b", "t", "ctrl-t",
    "p", "n", "]", "[", "ctrl-shift-d", "h", "j", "k", "l", "x", "shift-x",
    "z", "shift-n", "shift-w", "shift-t", "?", "shift-/", "g", "ctrl-j",
    "tab", "shift-tab", "up", "down", "left", "right", "q", "ctrl-c",
    "ctrl-g", "enter", ..."123456789",
  ]) app.key(key);
  assert.deepEqual(app.calls, []);
  app.key("escape");
  assert.deepEqual(app.calls.map(([name]) => name), ["close", "pbogut-keys.closed-test-overlay"]);
});

test("the zero-height anchor toggles a frameless overlay without resizing the layout", async () => {
  const app = await fixture("pbogut-keys", false, false);
  for (const zoom of [1, 1.1]) {
    app.config.zoom = zoom;
    app.view.width = 1280 - 269 * zoom;
    await app.command("toggle");
    const [name, spec] = app.calls.at(-1);
    assert.equal(name, "open");
    assert.equal(spec.frame, "none");
    assert.equal(spec.width * zoom, app.view.width);
    assert.equal(spec.height, 36);
    assert.equal(spec.at.x + spec.width * zoom, 1280);
    assert.equal(spec.at.y + (spec.height + 42 + 28) * zoom, 800);
    await app.command("toggle");
    assert.equal(app.calls.at(-1)[0], "close");
    await app.command("closed-test-overlay");
    assert.equal(app.view.overlay, null);
  }
  assert.ok(app.calls.every(([name]) => name === "open" || name === "close"));
});

test("copy cursor collapses only after the host reports the new endpoint", async () => {
  const app = await fixture("pbogut-copy");
  app.key("h");
  app.view.render();
  assert.deepEqual(app.terminal.selection.start, { row: 10, col: 5 });
  app.terminal.selection.end = { row: 10, col: 4 };
  app.view.render();
  assert.deepEqual(app.terminal.selection.start, { row: 10, col: 4 });
  app.key("v");
  app.key("l");
  app.terminal.selection.end = { row: 10, col: 8 };
  app.view.render();
  assert.deepEqual(app.terminal.selection.start, { row: 10, col: 4 });
  app.key("y");
  assert.deepEqual(app.calls.slice(-4).map(([name]) => name),
    ["terminal.copy", "close", "terminal.clear_selection", "terminal.scroll"]);
  assert.equal(app.terminal.selection, null);
});

test("Escape cleans up copy mode, including when the host closes the popup", async () => {
  const app = await fixture("pbogut-copy");
  app.view.close();
  assert.equal(app.terminal.selection, null);
  assert.equal(app.calls.at(-1)[1].terminal, "test/t1");
});

test("checking a mod never changes the terminal on cleanup", async () => {
  const app = await fixture("pbogut-copy", true);
  assert.equal(app.terminal.selection, null, "Check must not start a selection");
  app.view.close();
  assert.deepEqual(app.calls, []);
});

test("Alt+Esc opens copy mode and Ctrl+G toggles the bottom overlay", async () => {
  const keys = JSON.parse(await readFile(new URL("../../keys.json", root), "utf8"));
  assert.equal(keys.global["alt-escape"], "mod.open:pbogut-copy");
  assert.equal(keys.global["ctrl-g"], "pbogut-keys.toggle");
  assert.equal(keys["mod:pbogut-keys"], undefined);
});
