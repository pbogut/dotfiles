import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";
import vm from "node:vm";
import { ASSIGNMENTS, assignmentKey, matchFolder, orderFolders, parseFolders } from "../../../dot_config/herdr-app/mods/pbogut-spaces/folders.js";

const config = parseFolders(await readFile(new URL("fixtures/folders.json", import.meta.url), "utf8"));

test("configured rules match namespaces on any machine without matching similar names", () => {
  for (const prefix of ["/storage/projects", "/srv/repos", "/home/someone/code"]) {
    assert.equal(matchFolder(`${prefix}/gitlab.com/example-work/pms`, config), "work");
    for (const host of ["github.com", "gitlab.com", "codeberg.org"]) {
      for (const owner of ["example-personal", "example-side-projects"]) {
        assert.equal(matchFolder(`${prefix}/${host}/${owner}/project`, config), "personal");
      }
    }
    for (const path of ["github.com/example-personal-extra", "github.com/not-example-personal", "gitlab.com/example-work-old", "other/github.com-example-personal"]) {
      assert.equal(matchFolder(`${prefix}/${path}/project`, config), "other");
    }
  }
  assert.equal(matchFolder("/home/example-personal/.local/share/chezmoi", config), "personal");
  assert.equal(matchFolder("/home/remote/.local/share/chezmoi/nested", config), "personal");
  assert.equal(matchFolder("/home/example-personal/unrelated", config), "other");
  assert.equal(matchFolder("", config), "other");
});

test("more specific rules win; absolute paths are anchored and trailing slashes are accepted", () => {
  const rules = parseFolders(JSON.stringify({
    ...config,
    rules: [
      { path: "gitlab.com/example-work/", folder: "work" },
      { path: "gitlab.com/example-work/sandbox", folder: "personal" },
      { path: "/srv/gitlab.com/example-work/sandbox", folder: "other" },
    ],
  }));
  assert.equal(matchFolder("/code/gitlab.com/example-work/sandbox/.bare/", rules), "personal");
  assert.equal(matchFolder("/code/gitlab.com/example-work/sandbox-more", rules), "work");
  assert.equal(matchFolder("/srv/gitlab.com/example-work/sandbox", rules), "other");
  assert.equal(matchFolder("/elsewhere/srv/gitlab.com/example-work/sandbox", rules), "personal");
});

test("invalid folder configuration is rejected rather than dropping unmatched rows", () => {
  for (const value of [
    null, {}, { ...config, folders: ["work", "work"] }, { ...config, fallback: "work" },
    { ...config, rules: [{ path: "gitlab.com", folder: "missing" }] },
    ...["~/.local", "../repo", "repo/*", "/", "///", "repo//other"].map(path => ({ ...config, rules: [{ path, folder: "work" }] })),
  ]) {
    assert.throws(() => parseFolders(JSON.stringify(value)));
  }
});

test("folder order stays inside machine blocks and retains sibling worktree order", () => {
  const rows = [
    { w: { id: "notes", folder: "/notes" } },
    { w: { id: "personal", folder: "/repos/github.com/example-personal/dotfiles" } },
    { w: { id: "main", folder: "/repos/gitlab.com/example-work/pms" }, tree: null },
    { w: { id: "worktree", folder: "/elsewhere" }, tree: "└─" },
    { w: { id: "remote-personal", folder: "/repos/github.com/example-side-projects/app", machine: "server" } },
    { w: { id: "remote-work", folder: "/repos/gitlab.com/example-work/api", machine: "server" } },
  ];
  const ordered = orderFolders(rows, config, space => matchFolder(space.id === "worktree" ? rows[2].w.folder : space.folder, config));
  assert.deepEqual(ordered.map(row => row.w.id), ["main", "worktree", "personal", "notes", "remote-work", "remote-personal"]);
  assert.equal(ordered[1].tree, "└─");
  assert.deepEqual(rows.map(row => row.w.id), ["notes", "personal", "main", "worktree", "remote-personal", "remote-work"]);
});

// Record native element callbacks so tests can fold a real sidebar header and
// check row indexes without running a window or touching the user's app state.
function element() {
  const value = { attrs: {}, nodes: [] };
  const el = new Proxy(value, { get(target, key) {
    if (key in target) return target[key];
    if (key === "child") return child => { value.nodes.push(child); return el; };
    if (key === "children") return children => { value.nodes.push(...children); return el; };
    if (key === "when") return (condition, callback) => condition ? callback(el) : el;
    return (...args) => {
      value.attrs[key] = args;
      if (key.startsWith("on_mouse_") && typeof args[0] === "string") value.attrs[`${key}:${args[0]}`] = args[1];
      return el;
    };
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

async function sidebar(spaces, storage = new Map(), shared = new Map()) {
  const tasks = [], moves = [];
  const state = { config: JSON.stringify(config), remote: [], scrolled: [], notices: [], overlays: [], commands: [], props: {},
    exec: async () => ({ code: 1, stdout: "", stderr: "not a git repository" }) };
  const context = vm.createContext({ Date, localStorage: {
    getItem: key => storage.get(key) ?? null, setItem: (key, value) => storage.set(key, value),
  } });
  const mock = values => new vm.SyntheticModule(Object.keys(values), function () {
    for (const [key, value] of Object.entries(values)) this.setExport(key, value);
  }, { context });
  const mods = {
    "gpui-kit": mock({ View: class {}, div: element, svg: element }),
    "gpui-base": mock({ v_flex: element, h_flex: element, ScrollHandle: { new: () => ({
      scroll_to_item: index => state.scrolled.push(index),
    }) } }),
    herdr: mock({
      spaces: () => spaces, panes: () => [], machines: () => [{ name: null, layout: "ready" }, ...state.remote.map(m => ({ ...m, layout: "ready" }))],
      window: () => ({ active: true }), layout: () => ({}), theme: () => ({}),
      run(command, args) {
        state.commands.push({ command, args });
        if (command !== "space.move") return;
        moves.push(args);
        const index = spaces.findIndex(s => s.id === args.id);
        spaces.splice(args.index - 1, 0, ...spaces.splice(index, 1));
      },
      openOverlay: options => state.overlays.push(options), closeOverlay() {}, keys: () => [], props: () => state.props,
      shared: key => shared.get(key), setShared: (key, value) => shared.set(key, value),
      watchFolder() {}, notify: value => state.notices.push(value),
      hc: async () => ({ code: 0, stdout: '{"machines":[]}' }), checking: () => true, nextCommand() {},
      appHome: () => "/app", readTextFile: async path => path === "/app/folders.json" ? state.config : null,
      exec: (...args) => state.exec(...args),
    }),
  };
  const source = new URL("../../../dot_config/herdr-app/mods/pbogut-spaces/main.js", import.meta.url);
  const folders = new vm.SourceTextModule(await readFile(new URL("folders.js", source), "utf8"), { context });
  await folders.link(() => {});
  const menu = new vm.SourceTextModule(await readFile(new URL("menu.js", source), "utf8"), { context });
  await menu.link(name => name === "./folders.js" ? folders : mods[name]);
  const main = new vm.SourceTextModule(await readFile(source, "utf8"), { context });
  await main.link(name => name === "./folders.js" ? folders : name === "./menu.js" ? menu : mods[name]);
  await main.evaluate();
  const cx = { spawn: callback => tasks.push(callback(cx)), notify() {}, stop_propagation() {},
    focus_handle: () => ({ focus() {} }), timer: { every() {} } };
  const view = new main.namespace.default();
  view.init({}, cx);
  const flush = async () => { while (tasks.length) await Promise.all(tasks.splice(0)); };
  const reload = async () => { view.reloadFolders(cx); await flush(); };
  await reload();
  const popup = () => {
    state.props = state.overlays.at(-1).props;
    const menuView = new main.namespace.default();
    menuView.init({}, cx);
    state.props = {};
    return menuView;
  };
  return { view, state, storage, shared, moves, cx, flush, reload, popup };
}

test("native indexes follow folder order on each machine, even with folded folders", async () => {
  const spaces = [
    { id: "notes", name: "notes", folder: "/notes" },
    { id: "personal", name: "dotfiles", folder: "/repos/github.com/example-personal/dotfiles" },
    { id: "work", name: "pms", folder: "/repos/gitlab.com/example-work/pms", active: true },
    { id: "remote-personal", name: "site", folder: "/srv/github.com/example-side-projects/site", machine: "server" },
    { id: "remote-work", name: "api", folder: "/srv/gitlab.com/example-work/api", machine: "server" },
  ];
  const { view, state, cx, moves } = await sidebar(spaces);
  state.remote = view.machines = [{ name: "server", state: "connected" }];
  let rows = view.grouped({}, false);
  assert.deepEqual(spaces.map(s => s.id), ["work", "personal", "notes", "remote-work", "remote-personal"]);
  assert.equal(rows[view.activeAt].attrs.id[0], "space-work");
  const moved = moves.length;
  const workHeader = rows.find(row => row.attrs.id[0] === 'folder-[null,"work"]');
  workHeader.attrs["on_mouse_up:left"](null, cx);
  rows = view.grouped({}, false);
  assert.equal(rows.some(row => row.attrs.id[0] === "space-work"), false, "The current folder can be folded manually");
  assert.equal(moves.length, moved, "Folding does not change native numbering");
  spaces.forEach(s => { s.active = s.id === "remote-work"; });
  view.folded.add("server");
  view.foldersFolded.add('["server","work"]');
  rows = view.grouped({}, false);
  assert.equal(view.folded.has("server"), false);
  assert.equal(view.foldersFolded.has('["server","work"]'), false);
  assert.equal(rows[view.activeAt].attrs.id[0], "space-remote-work", "Scroll index includes earlier machines and folders");
  spaces.forEach(s => { s.active = s.id === "work"; });
  rows = view.grouped({}, false);
  assert.equal(rows[view.activeAt].attrs.id[0], "space-work", "Switching back reveals the folded folder");
});

test("empty-folder toggle and folding persist across sidebar reloads", async () => {
  const spaces = [{ id: "notes", name: "notes", folder: "/notes", active: true }];
  const app = await sidebar(spaces);
  let tree = app.view.render(app.cx);
  assert.equal(find(tree, 'folder-[null,"work"]'), undefined);
  find(tree, "space-empty-folders").attrs.on_click[0](null, app.cx);
  tree = app.view.render(app.cx);
  assert.ok(find(tree, 'folder-[null,"work"]'));
  assert.ok(find(tree, 'folder-[null,"personal"]'));
  find(tree, 'folder-[null,"work"]').attrs["on_mouse_up:left"](null, app.cx);
  await app.flush();
  const reopened = await sidebar(spaces, app.storage);
  assert.equal(reopened.view.showEmptyFolders, true);
  assert.equal(reopened.view.foldersFolded.has('[null,"work"]'), true);
  const next = reopened.view.render(reopened.cx);
  find(next, "space-empty-folders").attrs.on_click[0](null, reopened.cx);
  assert.equal(find(reopened.view.render(reopened.cx), 'folder-[null,"work"]'), undefined);
  await reopened.flush();
});

test("invalid edited config keeps the last rules, then a corrected config changes grouping", async () => {
  const space = { id: "work", folder: "/code/gitlab.com/example-work/pms" };
  const app = await sidebar([space]);
  assert.equal(app.view.folderFor(space), "work");
  app.state.config = '{"folders":';
  await app.reload();
  assert.match(app.view.folderError, /folders.json/);
  assert.equal(app.view.folderFor(space), "work");
  app.state.config = JSON.stringify({ ...config, rules: [] });
  await app.reload();
  assert.equal(app.view.folderError, null);
  assert.equal(app.view.folderFor(space), "other");
});

test("manual assignments follow a repository across worktrees and reopened spaces, separately per machine", async () => {
  const root = "/code/gitlab.com/example-work/app";
  const spaces = [
    { id: "main", folder: `${root}/main` },
    { id: "linked", folder: "/elsewhere/task" },
    { id: "remote", folder: `${root}/main`, machine: "server" },
  ];
  const app = await sidebar(spaces);
  for (const s of spaces) app.view.projects.set(JSON.stringify([s.machine ?? null, s.folder]), {
    root, directory: `${root}/.bare`,
  });
  app.view.assignFolder(spaces[1], "other", app.cx);
  await app.flush();
  assert.deepEqual(spaces.map(s => app.view.folderFor(s)), ["other", "other", "work"]);
  assert.equal(app.shared.get(ASSIGNMENTS)[assignmentKey(null, `${root}/.bare/`)], "other");
  spaces.splice(0, 2, { id: "new-space", folder: "/another/worktree" });
  const reopened = await sidebar(spaces, app.storage, app.shared);
  reopened.view.projects.set(JSON.stringify([null, spaces[0].folder]), { root, directory: `${root}/.bare` });
  assert.equal(reopened.view.folderFor(spaces[0]), "other");
  reopened.view.assignFolder(spaces[0], "personal", reopened.cx);
  await reopened.flush();
  assert.equal(reopened.view.folderFor(spaces[0]), "personal");
  reopened.view.folderConfig = { ...config, folders: ["work"] };
  assert.equal(reopened.view.folderFor(spaces[0]), "work", "A removed folder's assignment falls back to current rules");
});

test("an early drop resolves the common directory; a failed remote lookup never writes an assignment", async () => {
  const space = { id: "linked", folder: "/temporary/worktree", machine: "server" };
  const app = await sidebar([space]);
  const calls = [];
  app.state.exec = async (_command, args, options) => {
    calls.push({ args, options });
    return { code: 0, stdout: "/repos/project/.git\n" };
  };
  app.view.assignFolder(space, "personal", app.cx);
  await app.flush();
  assert.equal(app.shared.get(ASSIGNMENTS)[assignmentKey("server", "/repos/project/.git")], "personal");
  assert.deepEqual(JSON.parse(JSON.stringify(calls[0].options)), { cwd: space.folder, on: "server" });
  assert.ok(calls[0].args.includes("--git-common-dir"));
  app.state.exec = async () => { throw new Error("offline"); };
  const before = JSON.stringify(app.shared.get(ASSIGNMENTS));
  app.view.assignFolder(space, "other", app.cx);
  await app.flush();
  assert.equal(JSON.stringify(app.shared.get(ASSIGNMENTS)), before);
  assert.match(app.state.notices.at(-1).body, /offline/);
});

test("folder-header drops move the whole repository but reject drops across machines", async () => {
  const root = "/repos/gitlab.com/example-work/app";
  const spaces = [
    { id: "main", name: "app", folder: `${root}/main`, active: true },
    { id: "linked", name: "feature", folder: "/elsewhere/task" },
    { id: "remote", name: "remote", folder: `${root}/main`, machine: "server" },
  ];
  const app = await sidebar(spaces);
  app.view.showEmptyFolders = true;
  app.state.remote = app.view.machines = [{ name: "server", state: "connected" }];
  for (const s of spaces) app.view.projects.set(JSON.stringify([s.machine ?? null, s.folder]), {
    root, directory: `${root}/.bare`,
  });
  let tree = app.view.render(app.cx);
  find(tree, "space-linked").attrs["on_mouse_down:left"]();
  const remote = find(tree, 'folder-["server","other"]');
  remote.attrs.on_mouse_move[0](null, app.cx);
  assert.equal(app.view.overFolder, null);
  remote.attrs["on_mouse_up:left"](null, app.cx);
  await app.flush();
  assert.equal(app.shared.has(ASSIGNMENTS), false);
  find(tree, "space-linked").attrs["on_mouse_down:left"]();
  const other = find(tree, 'folder-[null,"other"]');
  other.attrs.on_mouse_move[0](null, app.cx);
  assert.equal(app.view.overFolder, '[null,"other"]');
  tree = app.view.render(app.cx);
  assert.ok(find(tree, 'folder-[null,"other"]').attrs.border, "A valid drop target is highlighted");
  find(tree, 'folder-[null,"other"]').attrs["on_mouse_up:left"](null, app.cx);
  await app.flush();
  assert.deepEqual(spaces.map(s => app.view.folderFor(s)), ["other", "other", "work"]);
  assert.equal(app.view.pressed, null);
  assert.equal(app.view.overFolder, null);
  assert.equal(app.view.foldersFolded.has('[null,"other"]'), false);
});

test("Use matching rules resets all local worktrees while retaining remote assignments and native menu actions", async () => {
  const root = "/repos/gitlab.com/example-work/app";
  const spaces = [
    { id: "main", folder: `${root}/main` }, { id: "linked", folder: "/elsewhere/worktree" },
    { id: "remote", folder: `${root}/main`, machine: "server" },
  ];
  const app = await sidebar(spaces);
  for (const s of spaces) app.view.projects.set(JSON.stringify([s.machine ?? null, s.folder]), {
    root, directory: `${root}/.bare`,
  });
  const local = assignmentKey(null, `${root}/.bare`), remote = assignmentKey("server", `${root}/.bare`);
  app.shared.set(ASSIGNMENTS, { [local]: "other", [remote]: "personal" });
  app.state.exec = async (_command, args) => ({ code: 0, stdout: `${args.includes("--git-common-dir") ? root + "/.bare" : root + "/main"}\n` });
  app.view.menu(spaces[1]);
  assert.equal(app.state.overlays.at(-1).mod, "pbogut-spaces");
  const popup = app.popup();
  await app.flush();
  assert.deepEqual(Array.from(popup.popup.items(), item => item[0]), [
    "Use matching rules", "Rename", "New worktree", "Open worktree", "Remove worktree", "Close",
  ]);
  popup.render(app.cx).attrs.on_key_down[0]({ key: "enter" }, app.cx);
  assert.deepEqual(spaces.map(s => app.view.folderFor(s)), ["work", "work", "personal"]);
  assert.equal(Object.keys(app.shared.get(ASSIGNMENTS)).length, 1);
  popup.popup.choose(0);
  assert.equal(app.state.commands.at(-1).command, "space.rename");
  assert.equal(app.state.commands.at(-1).args.id, "linked");
  popup.popup.choose(2);
  assert.equal(app.state.overlays.at(-1).mod, "worktree");
  assert.equal(app.state.overlays.at(-1).props.action, "open");
});

test("an in-flight drop is discarded if its space closes before repository resolution", async () => {
  const spaces = [{ id: "closing", folder: "/temporary/worktree" }];
  const app = await sidebar(spaces);
  let release;
  app.state.exec = () => new Promise(resolve => { release = resolve; });
  app.view.assignFolder(spaces[0], "personal", app.cx);
  spaces.length = 0;
  release({ code: 0, stdout: "/repo/.git\n" });
  await app.flush();
  assert.equal(app.shared.has(ASSIGNMENTS), false);
});
