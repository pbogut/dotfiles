import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";
import vm from "node:vm";

function element() {
  const value = { attrs: {}, nodes: [] };
  const el = new Proxy(value, { get(target, key) {
    if (key in target) return target[key];
    if (key === "child") return child => { value.nodes.push(child); return el; };
    if (key === "children") return children => { value.nodes.push(...children); return el; };
    if (key === "when") return (condition, callback) => condition ? callback(el) : el;
    return (...args) => { value.attrs[key] = args; return el; };
  } });
  return el;
}

function find(el, id) {
  if (el?.attrs?.id?.[0] === id) return el;
  for (const child of el?.nodes ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
}

function text(el) {
  return typeof el === "string" ? el : (el?.nodes ?? []).map(text).filter(Boolean).join(" ");
}

function tooltips(el) {
  return [...(el?.attrs?.tooltip ?? []), ...(el?.nodes ?? []).flatMap(tooltips)];
}

function agent(address, space, status, extra = {}) {
  return { address, space, status, space_name: space, pane: `pane-${address}`, tab: `tab-${address}`,
    seq: 0, program: { name: "OpenCode", key: "opencode", agent: true }, ...extra };
}

async function sidebar(list, sort) {
  const shared = new Map(sort ? [["agents.sort", sort]] : []);
  const storage = new Map();
  const state = {
    agents: list, terminals: [], panes: [], props: {}, width: 268, commands: [], overlays: [], order: [],
    spaces: [...new Set(list.map(a => a.space))].map(id => ({
      id, name: id, tabs: list.filter(a => a.space === id).map(a => ({ id: a.tab, name: "oc-1", named: true })),
    })),
  };
  const context = vm.createContext({ Date, localStorage: {
    getItem: key => storage.get(key) ?? null, setItem: (key, value) => storage.set(key, value),
    removeItem: key => storage.delete(key),
  } });
  const mock = values => new vm.SyntheticModule(Object.keys(values), function () {
    for (const [key, value] of Object.entries(values)) this.setExport(key, value);
  }, { context });
  const modules = {
    "gpui-kit": mock({ View: class {}, div: element, svg: element, image: element }),
    "gpui-base": mock({ v_flex: element, h_flex: element }),
    herdr: mock({
      agents: () => state.agents, terminals: () => state.terminals, panes: () => state.panes,
      focused: () => ({}), spaces: () => state.spaces, theme: () => ({}), props: () => state.props,
      window: () => ({}), layout: () => ({ id: "sidebar", size: { px: state.width } }),
      shared: key => shared.get(key), setShared: (key, value) => shared.set(key, value),
      setAgentOrder: addresses => { state.order = Array.from(addresses); },
      run: (command, args) => state.commands.push([command, args]),
      openOverlay: options => state.overlays.push(options), closeOverlay() {},
    }),
  };
  const main = new vm.SourceTextModule(await readFile(new URL(
    "../../../dot_config/herdr-app/mods/pbogut-agents/main.js", import.meta.url), "utf8"), { context });
  await main.link(name => modules[name]);
  await main.evaluate();
  const cx = { timer: { every() {} }, notify() {}, stop_propagation() {} };
  const view = new main.namespace.default();
  view.init({}, cx);
  const render = () => view.render(cx);
  return { view, state, shared, cx, render,
    rows: () => Array.from(find(render(), "ag-list").nodes, row => row.attrs.id[0]) };
}

test("existing sort selection, pinned agents, and priority navigation survive the custom mod", async () => {
  const app = await sidebar([
    agent("idle", "work", "idle"), agent("working", "personal", "working"),
    agent("blocked", "work", "blocked"), agent("pin", "personal", "idle", { pinned: true }),
  ]);
  assert.deepEqual(app.rows(), ["pinned", "ag-pin", "sec-4", "ag-blocked", "sec-2", "ag-working", "sec-1", "ag-idle"]);
  assert.deepEqual(app.state.order, ["pin", "blocked", "working", "idle"]);
  assert.equal(app.shared.has("agents.sort"), false);
  app.shared.set("agents.sort", "grouped");
  assert.deepEqual(app.rows(), ["pinned", "ag-pin", "sp-work", "ag-idle", "sp-personal", "ag-working", "sp-work", "ag-blocked"]);
  assert.equal(app.shared.get("agents.sort"), "grouped");
  find(app.render(), "ag-working").attrs.on_click[0]();
  assert.deepEqual(JSON.parse(JSON.stringify(app.state.commands)), [["pane.focus", { pane: "pane-working" }]]);
});

const folder = name => JSON.stringify(["folder", name]);
const section = (name, rank) => JSON.stringify(["folder-section", name, rank]);

function resolved(app, rows) {
  app.shared.set("pbogut.spaces.folders", { names: ["work", "personal", "other"], fallback: "other" });
  app.shared.set("pbogut.spaces.rows", rows);
}

test("Folder + priority nests nonempty priority sections in configured folder order, with global pins", async () => {
  const app = await sidebar([
    agent("personal-blocked", "dotfiles", "blocked"), agent("work-idle", "api", "idle"),
    agent("work-done", "api", "done"), agent("work-busy", "api", "working"),
    agent("server/blocked", "remote-api", "blocked"), agent("pin", "dotfiles", "idle", { pinned: true }),
  ], "folder-priority");
  resolved(app, [
    { id: "dotfiles", folder: "personal" }, { id: "api", folder: "work" }, { id: "remote-api", folder: "work" },
  ]);
  assert.deepEqual(app.rows(), [
    "pinned", "ag-pin", folder("work"),
    section("work", 4), "ag-server/blocked", section("work", 3), "ag-work-done",
    section("work", 2), "ag-work-busy", section("work", 1), "ag-work-idle",
    folder("personal"), section("personal", 4), "ag-personal-blocked",
  ]);
  assert.deepEqual(app.state.order, ["pin", "server/blocked", "work-done", "work-busy", "work-idle", "personal-blocked"]);
  const order = [...app.state.order];
  find(app.render(), folder("work")).attrs.on_click[0](null, app.cx);
  assert.deepEqual(app.rows(), ["pinned", "ag-pin", folder("work"), folder("personal"), section("personal", 4), "ag-personal-blocked"]);
  assert.deepEqual(app.state.order, order, "Folding keeps agents reachable through next/previous");
  find(app.render(), folder("work")).attrs.on_click[0](null, app.cx);
  find(app.render(), section("work", 4)).attrs.on_click[0](null, app.cx);
  assert.equal(app.rows().includes("ag-server/blocked"), false);
  assert.equal(app.rows().includes("ag-personal-blocked"), true, "Same priority in another folder folds independently");
  app.state.width = 44;
  assert.deepEqual(app.rows(), order.map(address => `ag-${address}`), "The rail uses the same agent order");
});

test("agents follow changed assignments, renamed folders, and unresolved spaces without reading folder rules", async () => {
  const app = await sidebar([
    agent("one", "local", "working"), agent("two", "remote", "blocked"), agent("new", "new-space", "idle"),
  ], "folder-priority");
  resolved(app, [{ id: "local", folder: "personal" }, { id: "remote", folder: "work" }]);
  assert.deepEqual(app.rows(), [
    folder("work"), section("work", 4), "ag-two", folder("personal"), section("personal", 2), "ag-one",
    folder("other"), section("other", 1), "ag-new",
  ]);
  app.shared.set("pbogut.spaces.folders", { names: ["home", "clients", "unfiled"], fallback: "unfiled" });
  app.shared.set("pbogut.spaces.rows", [{ id: "local", folder: "clients" }, { id: "remote", folder: "home" }]);
  assert.deepEqual(app.rows(), [
    folder("home"), section("home", 4), "ag-two", folder("clients"), section("clients", 2), "ag-one",
    folder("unfiled"), section("unfiled", 1), "ag-new",
  ]);
  app.shared.get("pbogut.spaces.rows")[0].folder = "home";
  assert.deepEqual(app.rows(), [
    folder("home"), section("home", 4), "ag-two", section("home", 2), "ag-one",
    folder("unfiled"), section("unfiled", 1), "ag-new",
  ]);
  app.state.agents = app.state.agents.filter(a => a.space !== "remote");
  app.state.spaces = app.state.spaces.filter(s => s.id !== "remote");
  assert.equal(app.rows().includes("ag-two"), false, "Stale published rows cannot resurrect a closed agent");
});

test("sub-agent urgency promotes its parent inside the same folder and state changes move sections", async () => {
  const app = await sidebar([
    agent("parent", "api", "idle"), agent("child", "api", "blocked"), agent("done", "api", "done"),
  ], "folder-priority");
  app.state.terminals = [{ address: "child", parent: "parent", state: "live", status: "blocked" }];
  resolved(app, [{ id: "api", folder: "work" }]);
  assert.deepEqual(app.rows(), [
    folder("work"), section("work", 4), "ag-parent", "sub-child", section("work", 3), "ag-done",
  ]);
  assert.deepEqual(app.state.order, ["parent", "done"]);
  find(app.render(), "sub-child").attrs.on_click[0]();
  assert.deepEqual(JSON.parse(JSON.stringify(app.state.commands.at(-1))), ["pane.focus", { terminal: "child" }]);
  app.state.agents[1].status = "done";
  assert.deepEqual(app.rows(), [
    folder("work"), section("work", 3), "ag-done", section("work", 1), "ag-parent", "sub-child",
  ]);
});

test("the sort menu opts into Folder + priority and can return to the existing modes", async () => {
  const app = await sidebar([], "grouped");
  find(app.render(), "ag-sort").attrs.on_click[0]();
  assert.equal(app.state.overlays.at(-1).mod, "pbogut-agents");
  app.state.props = { sortMenu: true, overlay: "sort" };
  find(app.render(), "sort-folder-priority").attrs.on_click[0]();
  assert.equal(app.shared.get("agents.sort"), "folder-priority");
  find(app.render(), "sort-priority").attrs.on_click[0]();
  assert.equal(app.shared.get("agents.sort"), "priority");
});

test("all sort modes show project and per-worktree branch on one line without tab names", async () => {
  const app = await sidebar([
    agent("one", "raw-main", "working"),
    agent("two", "raw-feature", "blocked"),
    agent("server/three", "raw-remote", "idle", { pinned: true }),
  ]);
  resolved(app, [
    { id: "raw-main", name: "PMS", branch: "main", folder: "work" },
    { id: "raw-feature", name: "PMS", branch: "2026-11-18-feature-branch", folder: "work" },
    { id: "raw-remote", name: "Remote API", branch: "master", folder: "work" },
  ]);
  for (const sort of ["priority", "grouped", "folder-priority"]) {
    app.shared.set("agents.sort", sort);
    const tree = app.render();
    assert.match(text(find(tree, "ag-one")), /PMS · main/);
    assert.match(text(find(tree, "ag-two")), /PMS · feature-branch/);
    assert.match(text(find(tree, "ag-server/three")), /Remote API · master server/);
    assert.equal(find(tree, "ag-two").attrs.h[0], 30);
    assert.ok(tooltips(find(tree, "ag-two")).includes("2026-11-18-feature-branch"));
    assert.doesNotMatch(text(find(tree, "ag-two")), /raw-feature|2026-11-18|oc-1/);
    if (sort === "grouped") assert.match(text(find(tree, "sp-raw-feature")), /^PMS/);
  }
  assert.equal(app.state.agents[1].space_name, "raw-feature", "Only the display label changes");
  app.state.width = 44;
  assert.equal(find(app.render(), "ag-two").attrs.tooltip[0], "PMS · 2026-11-18-feature-branch");
});

test("labels follow refreshed shared data and fall back to the native name while a space resolves", async () => {
  const app = await sidebar([agent("one", "scratch", "idle")], "folder-priority");
  let row = find(app.render(), "ag-one");
  assert.match(text(row), /^scratch /);
  assert.doesNotMatch(text(row), /·/);
  resolved(app, [{ id: "scratch", name: "Project name", branch: "main", folder: "personal" }]);
  assert.match(text(find(app.render(), "ag-one")), /^Project name · main/);
  app.shared.set("pbogut.spaces.rows", [{ id: "scratch", name: "Renamed", branch: "2026-11-19-fix", folder: "personal" }]);
  assert.match(text(find(app.render(), "ag-one")), /^Renamed · fix/);
  app.shared.set("pbogut.spaces.rows", [{ id: "scratch", name: "Non-Git project", branch: "", folder: "personal" }]);
  row = find(app.render(), "ag-one");
  assert.match(text(row), /^Non-Git project /);
  assert.doesNotMatch(text(row), /·|main|fix/);
});

test("matching project labels keep separate focus targets without adding titles or tab numbers", async () => {
  const app = await sidebar([
    agent("one", "space", "working", { tab: "split", title: "✦ Fix login" }),
    agent("two", "space", "working", { tab: "split", title: "[ ! ] Review login" }),
  ]);
  resolved(app, [{ id: "space", name: "API", branch: "fix", folder: "work" }]);
  app.state.spaces[0].tabs = [{ id: "split", name: "oc-1", named: true }];
  for (const address of ["one", "two"]) {
    const row = find(app.render(), `ag-${address}`);
    assert.match(text(row), /^API · fix/);
    assert.doesNotMatch(text(row), /Fix login|Review login|oc-1/);
    assert.deepEqual(tooltips(row), ["API", "fix"]);
    row.attrs.on_click[0]();
    assert.equal(app.state.commands.at(-1)[1].pane, `pane-${address}`);
  }
  app.state.agents = [agent("one", "first", "idle"), agent("two", "second", "idle")];
  app.state.spaces = [{ id: "first", tabs: [{ id: "tab-one", name: "1", named: true }] },
    { id: "second", tabs: [{ id: "tab-two", name: "2", named: true }] }];
  resolved(app, [{ id: "first", name: "API", branch: "main", folder: "work" },
    { id: "second", name: "API", branch: "main", folder: "work" }]);
  for (const address of ["one", "two"]) {
    const row = find(app.render(), `ag-${address}`);
    assert.equal(text(row), "API · main <1m");
    assert.equal(row.attrs.h[0], 30);
  }
});
