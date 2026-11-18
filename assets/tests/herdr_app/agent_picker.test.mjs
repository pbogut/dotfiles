import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";
import vm from "node:vm";

function element(kind = "div", source) {
  const value = { attrs: {}, nodes: [], kind, source };
  const el = new Proxy(value, { get(target, key) {
    if (key in target) return target[key];
    if (key === "child") return child => { value.nodes.push(child); return el; };
    if (key === "children") return children => { value.nodes.push(...children); return el; };
    if (key === "when") return (condition, callback) => condition ? callback(el) : el;
    return (...args) => { value.attrs[key] = args; return el; };
  } });
  return el;
}

const walk = el => [el, ...(el?.nodes ?? []).flatMap(walk)];
const find = (el, id) => walk(el).find(node => node?.attrs?.id?.[0] === id);
const text = el => walk(el).filter(node => typeof node === "string").join(" ");

async function picker() {
  const state = {
    current: "local", calls: [], scrolled: [], overlays: [],
    agents: [
      { address: "local", space: "s-local", space_name: "raw-local", status: "working",
        program: { name: "OpenCode", icon: "icons/opencode.svg", tint: true } },
      { address: "server/t2", space: "s-remote", space_name: "raw-remote", status: "idle",
        program: { name: "Other agent", icon: "icons/other.png", tint: false } },
    ],
    terminals: [],
    spaces: [
      { id: "s-local", name: "raw-local", folder: "/repos/app/worktree" },
      { id: "s-remote", name: "raw-remote", machine: "server", folder: "/srv/app/main" },
    ],
  };
  const shared = new Map([["pbogut.agents.rows", [
    { address: "server/t2", name: "Project", branch: "main", folder: "personal",
      machine: "server", path: "/srv/app/main", compact: true },
    { address: "local", name: "Project", branch: "2026-11-18-feature", folder: "work",
      machine: null, path: "/repos/app/worktree", compact: true },
  ]]]);
  const context = vm.createContext({ window: { viewport_size: () => ({ height: 800 }) } });
  const events = {};
  let query = "";
  const input = { on: (event, callback) => { events[event] = callback; }, value: () => query, focus() {} };
  const mock = values => new vm.SyntheticModule(Object.keys(values), function () {
    for (const [key, value] of Object.entries(values)) this.setExport(key, value);
  }, { context });
  const modules = {
    "gpui-kit": mock({ View: class {}, div: () => element(), svg: source => element("svg", source),
      image: source => element("image", source) }),
    "gpui-base": mock({
      v_flex: () => element(), h_flex: () => element(), InputState: { new: () => input }, Input: { new: () => element() },
      v_virtual_list: (id, count, height, key, render) => element().id(id).children(render({ start: 0, end: count })),
      VirtualListScrollHandle: { new: () => ({ scroll_to_item: index => state.scrolled.push(index) }) },
    }),
    herdr: mock({
      agents: () => state.agents, terminals: () => state.terminals, spaces: () => state.spaces,
      focused: () => ({ agent: state.current }), shared: key => shared.get(key),
      settings: () => ({ zoom: 1 }), theme: () => ({ working: "#00ff00", foreground: "#ffffff" }),
      props: () => ({ overlay: "agents" }), closeOverlay: () => state.calls.push(["close"]),
      openOverlay: options => state.overlays.push(options),
      run: (command, args) => state.calls.push([command, args.terminal]),
    }),
  };
  const source = new URL("../../../dot_config/herdr-app/mods/pbogut-agents/picker.js", import.meta.url);
  const appearance = new vm.SourceTextModule(await readFile(new URL("appearance.js", source), "utf8"), { context });
  await appearance.link(name => modules[name]);
  const main = new vm.SourceTextModule(await readFile(source, "utf8"), { context });
  await main.link(name => name === "./appearance.js" ? appearance : modules[name]);
  await main.evaluate();
  const cx = { focus_handle() {}, notify() {}, stop_propagation() {} };
  const view = new main.namespace.default();
  view.init({}, cx);
  const render = () => view.render();
  render();
  return {
    view, state, shared, render,
    ids: () => Array.from(view.rows(), row => row.address),
    search(value) { query = value; events.change(null, cx); render(); },
    key(key) { render().attrs.on_key_down[0]({ key, keystroke: key }, cx); render(); },
    submit: () => events.submit(),
    click(address) { find(render(), "agent-picker-list").attrs.on_item_click[0](address); },
  };
}

test("picker follows the published sidebar order, starts on the current agent, and searches both lines", async () => {
  const app = await picker();
  assert.deepEqual(app.ids(), ["server/t2", "local"]);
  assert.equal(app.view.selected, "local");
  app.search("project");
  assert.deepEqual(app.ids(), ["server/t2", "local"], "Filtering retains the sidebar order");
  assert.equal(app.view.selected, "server/t2");
  app.search("work FEATURE");
  assert.deepEqual(app.ids(), ["local"]);
  const row = find(app.render(), "agent-picker-local");
  assert.match(text(row), /Project feature This computer · work · \/repos\/app\/worktree/);
  assert.doesNotMatch(text(row), /raw-local|2026-11-18/);
  assert.ok(walk(row).some(el => el?.attrs?.tooltip?.[0] === "2026-11-18-feature"));
  assert.equal(row.attrs.h[0], 48);
  app.search("server /srv");
  assert.deepEqual(app.ids(), ["server/t2"]);
  app.submit();
  assert.deepEqual(app.state.calls, [["close"], ["agent.focus", "server/t2"]]);
});

test("program icons and live working/status indicators use the sidebar renderer", async () => {
  const app = await picker();
  let row = find(app.render(), "agent-picker-local");
  const glyph = walk(row).find(el => el.source === "icons/opencode.svg");
  assert.equal(glyph.kind, "svg");
  assert.equal(glyph.attrs.size[0], 16);
  const spinner = walk(row).find(el => el.source === "mods/workspace-chrome/spinner.svg");
  assert.equal(spinner.attrs.spin[0], 900);
  assert.equal(spinner.attrs.text_color[0], "#00ff00");
  const picture = walk(find(app.render(), "agent-picker-server/t2")).find(el => el.source === "icons/other.png");
  assert.equal(picture.kind, "image");
  assert.equal(picture.attrs.w[0], 16);
  app.state.agents[0].status = "blocked";
  row = find(app.render(), "agent-picker-local");
  assert.match(text(row), /!/);
  assert.equal(walk(row).some(el => el.source === "mods/workspace-chrome/spinner.svg"), false);
  app.shared.get("pbogut.agents.rows")[1].compact = false;
  assert.match(text(find(app.render(), "agent-picker-local")), /Needs you/);
  assert.equal(app.view.selected, "local", "Status changes keep the selection on the same agent");
});

test("live reordering preserves selection, closes remove rows, and new agents stay reachable", async () => {
  const app = await picker();
  app.shared.get("pbogut.agents.rows").reverse();
  app.render();
  assert.equal(app.view.at, 0);
  assert.equal(app.view.selected, "local");
  app.state.agents = app.state.agents.filter(a => a.address !== "local");
  app.submit();
  assert.deepEqual(app.state.calls, [], "An agent that closed after selection cannot be focused");
  app.render();
  assert.deepEqual(app.ids(), ["server/t2"]);
  app.state.agents.push({ address: "new", space: "s-new", space_name: "New project", status: "idle" });
  app.state.spaces.push({ id: "s-new", name: "New project", folder: "/new" });
  assert.deepEqual(app.ids(), ["server/t2", "new"]);
  app.click("new");
  assert.deepEqual(app.state.calls, [["close"], ["agent.focus", "new"]]);
});

test("Ctrl+J/K and arrow navigation wrap, empty search cannot select, and Escape closes", async () => {
  const app = await picker();
  app.key("ctrl-j");
  assert.equal(app.view.selected, "server/t2");
  app.key("up");
  assert.equal(app.view.selected, "local");
  app.search("nothing-matches");
  app.key("ctrl-j");
  app.key("ctrl-k");
  app.submit();
  assert.deepEqual(app.state.calls, []);
  assert.equal(app.view.at, 0);
  app.search("");
  app.key("ctrl-k");
  assert.equal(app.view.selected, "local");
  app.key("down");
  assert.equal(app.view.selected, "server/t2");
  app.key("escape");
  assert.deepEqual(app.state.calls, [["close"]]);
});

test("detached sub-agents keep their parent metadata and are selectable until they exit", async () => {
  const app = await picker();
  app.shared.get("pbogut.agents.rows").push({
    ...app.shared.get("pbogut.agents.rows")[1], address: "child", parent: "local", depth: 1,
  });
  app.state.terminals = [{ address: "child", parent: "local", state: "live", status: "done",
    program: { icon: "icons/child.svg", tint: true } }];
  assert.deepEqual(app.ids(), ["server/t2", "local", "child"]);
  assert.equal(app.view.rows().at(-1).status, "idle", "A child's done state is not a separate finished parent");
  app.view.selected = "child";
  app.state.terminals[0].state = "exited";
  app.submit();
  assert.deepEqual(app.state.calls, []);
  assert.deepEqual(app.ids(), ["server/t2", "local"]);
  app.state.terminals[0].state = "live";
  app.state.terminals[0].status = "error";
  assert.equal(app.view.rows().at(-1).status, "blocked");
  app.click("child");
  assert.deepEqual(app.state.calls, [["close"], ["agent.focus", "child"]]);
});
