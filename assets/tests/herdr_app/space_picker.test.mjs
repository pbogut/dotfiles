import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";
import vm from "node:vm";

async function picker() {
  const state = {
    spaces: [
      { id: "second", name: "Second", active: true, status: "blocked" },
      { id: "first", name: "First", status: null },
    ],
    rows: [{ id: "first", name: "Project", branch: "main" }, { id: "second", name: "Project", branch: "feature" }],
    calls: [], scrolled: [],
  };
  const context = vm.createContext({ window: { viewport_size: () => ({ height: 800 }) } });
  const element = () => {
    const attrs = {};
    const el = new Proxy({ attrs }, { get(target, key) {
      if (key in target) return target[key];
      if (key === "when") return (condition, callback) => condition ? callback(el) : el;
      return (...args) => { attrs[key] = args; return el; };
    } });
    return el;
  };
  const events = {};
  let query = "";
  const input = { on: (event, callback) => { events[event] = callback; }, value: () => query, focus() {} };
  const mock = values => new vm.SyntheticModule(Object.keys(values), function () {
    for (const [key, value] of Object.entries(values)) this.setExport(key, value);
  }, { context });
  const modules = {
    "gpui-kit": mock({ View: class {}, div: element, svg: element }),
    "gpui-base": mock({
      v_flex: element, h_flex: element, InputState: { new: () => input }, Input: { new: element },
      v_virtual_list: element, Scrollbar: { vertical: element },
      VirtualListScrollHandle: { new: () => ({ scroll_to_item: index => state.scrolled.push(index) }) },
    }),
    herdr: mock({
      spaces: () => state.spaces, shared: () => state.rows, props: () => ({ overlay: "spaces" }),
      settings: () => ({ zoom: 1 }), theme: () => ({}),
      closeOverlay: () => state.calls.push(["close"]),
      run: (command, args) => state.calls.push([command, args.id]),
    }),
  };
  const main = new vm.SourceTextModule(await readFile(new URL(
    "../../../dot_config/herdr-app/mods/pbogut-spaces/picker.js", import.meta.url), "utf8"), { context });
  await main.link(name => modules[name]);
  await main.evaluate();
  const cx = { focus_handle() {}, notify() {}, stop_propagation() {} };
  const view = new main.namespace.default({ overlay: "spaces" }, cx);
  view.render();
  return {
    view, state,
    ids: () => Array.from(view.rows(), row => row.w.id),
    search(value) { query = value; events.change(null, cx); view.render(); },
    key(key) { view.render().attrs.on_key_down[0]({ key, keystroke: key }, cx); view.render(); },
    submit: () => events.submit(),
  };
}

test("space results follow the sidebar rather than activity, and filtering retains that order", async () => {
  const app = await picker();
  assert.deepEqual(app.ids(), ["first", "second"]);
  assert.equal(app.view.selected, "second");
  app.search("project");
  assert.deepEqual(app.ids(), ["first", "second"]);
  assert.equal(app.view.selected, "first");
  app.search("project FEATURE");
  assert.deepEqual(app.ids(), ["second"]);
  app.submit();
  assert.deepEqual(app.state.calls, [["close"], ["space.select", "second"]]);
});

test("live sidebar reordering retains the selected space, and closed rows are removed", async () => {
  const app = await picker();
  app.state.rows.reverse();
  app.view.render();
  assert.equal(app.view.at, 0);
  assert.equal(app.view.selected, "second");
  assert.equal(app.state.scrolled.at(-1), 0);
  app.state.spaces = app.state.spaces.filter(w => w.id !== "second");
  app.submit();
  assert.deepEqual(app.state.calls, [], "A selection removed before the next frame does nothing");
  app.view.render();
  assert.deepEqual(app.ids(), ["first"]);
  assert.equal(app.view.selected, "first");
  app.state.spaces.push({ id: "new", name: "New space" });
  assert.deepEqual(app.ids(), ["first", "new"], "A new space remains reachable before the sidebar resolves it");
});

test("empty results cannot switch spaces, navigation recovers after clearing the search", async () => {
  const app = await picker();
  app.search("missing");
  app.key("ctrl-j");
  app.key("ctrl-k");
  app.submit();
  assert.deepEqual(app.state.calls, []);
  assert.equal(app.view.at, 0);
  app.search("");
  app.key("ctrl-k");
  assert.equal(app.view.selected, "second");
  app.key("down");
  assert.equal(app.view.selected, "first");
  app.key("escape");
  assert.deepEqual(app.state.calls, [["close"]]);
});
