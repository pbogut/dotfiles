import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";
import vm from "node:vm";

const root = new URL("../../../dot_config/herdr-app/mods/pbogut-tabs/", import.meta.url);

async function fixture(checking = false) {
  const calls = [], commands = [], operations = [], timers = [], reads = [];
  const files = new Map(), persisted = new Map();
  files.set("/config/herdr-app/herdr-project.json", '{"tabs":["nvim"]}');
  const failures = new Set();
  const spaces = [
    { id: "one", active: true, folder: "/project one", tabs: [{ id: "original", name: "1", named: false }] },
    { id: "two", active: false, folder: "/project two", tabs: [{ id: "other", name: "shell", named: true }] },
  ];
  let receive, serial = 0;
  const context = vm.createContext({});
  const element = { h: () => element };
  function mock(values) {
    return new vm.SyntheticModule(Object.keys(values), function () {
      for (const [key, value] of Object.entries(values)) this.setExport(key, value);
    }, { context });
  }
  const modules = {
    "gpui-kit": mock({ View: class {}, div: () => element }),
    herdr: mock({
      checking: () => checking, spaces: () => structuredClone(spaces),
      exec: async (name, _args, { cwd }) => ({ code: 0,
        stdout: name === "sh" ? "/remote/home\n/remote/app\n" : `${cwd}/.bare\n` }),
      readTextFile: async (path, { on }) => {
        reads.push(path);
        return files.get(on ? `${on}:${path}` : path) ?? null;
      },
      shared: (key) => persisted.get(key),
      setShared: (key, value) => persisted.set(key, JSON.parse(JSON.stringify(value))),
      appHome: () => "/config/herdr-app", home: () => "/home/test",
      notify: (args) => calls.push(["notify", args]),
      nextCommand: () => commands.length ? Promise.resolve(commands.shift())
        : new Promise((resolve) => { receive = resolve; }),
      run: (name, args) => {
        if (failures.has(name)) throw new Error(`${name} unavailable`);
        const operation = [name, JSON.parse(JSON.stringify(args ?? {}))];
        calls.push(operation);
        if (!name.startsWith("pbogut-spaces.")) operations.push(operation);
      },
    }),
    "./roles.js": new vm.SourceTextModule(await readFile(new URL("roles.js", root), "utf8"), { context }),
    "./project.js": new vm.SourceTextModule(await readFile(new URL("project.js", root), "utf8"), { context }),
  };
  const main = new vm.SourceTextModule(await readFile(new URL("main.js", root), "utf8"), { context });
  await main.link((name) => modules[name]);
  await main.evaluate();
  const cx = { spawn: (fn) => fn(cx), notify: () => view.render(cx), timer: { after: (_ms, fn) => timers.push(fn) } };
  const view = new main.namespace.default();
  view.init({}, cx);
  return {
    calls, spaces, timers, files, failures, reads, persisted,
    roles: modules["./roles.js"].namespace,
    render: () => view.render(cx),
    async command(value) {
      if (receive) {
        const resolve = receive;
        receive = null;
        resolve(value);
      } else commands.push(value);
      await new Promise(setImmediate);
    },
    flush() {
      while (operations.length) {
        for (const [name, args] of operations.splice(0)) {
          if (name === "space.new") {
            spaces.forEach((space) => { space.active = false; });
            const id = `${args.machine ? `${args.machine}/` : ""}space-${++serial}`;
            spaces.push({ id, folder: args.folder, name: args.name, machine: args.machine || null, active: true,
              tabs: [{ id: `${id}-initial`, name: "1", named: false, panes: 1 }] });
          } else if (name === "space.select") {
            spaces.forEach((space) => { space.active = space.id === args.id; });
          } else if (name === "tab.new") {
            if (failures.has(args.name)) continue;
            spaces.find((space) => space.id === args.space).tabs.push({ id: `new-${++serial}`, name: args.name, named: true });
          } else {
            const space = spaces.find((space) => space.tabs.some((tab) => tab.id === args.id));
            const index = space.tabs.findIndex((tab) => tab.id === args.id);
            if (name === "tab.move") space.tabs.splice(args.index - 1, 0, ...space.tabs.splice(index, 1));
            if (name === "tab.rename") space.tabs[index].name = args.name;
            if (name === "tab.close") space.tabs.splice(index, 1);
            if (name === "tab.select") {
              spaces.forEach((candidate) => { candidate.active = candidate === space; });
              space.selected = args.id;
            }
          }
        }
        view.render(cx);
      }
    },
  };
}

test("an existing role only focuses its tab in the requested space", async () => {
  const app = await fixture();
  await app.command("shell@two");
  assert.deepEqual(app.calls, [["tab.select", { id: "other" }]]);
});

test("rapid repeated requests create one tab and preserve the original terminal", async () => {
  const app = await fixture();
  for (let i = 0; i < 20; i++) await app.command("shell");
  assert.deepEqual(app.calls, [["tab.new", { name: "shell", space: "one", folder: "/project one", focus: false }]]);
  app.flush();
  assert.deepEqual(app.spaces[0].tabs.map((tab) => tab.name), ["shell", "1"]);
  assert.equal(app.spaces[0].tabs[1].id, "original");
  await app.command("shell");
  assert.equal(app.calls.filter(([name]) => name === "tab.new").length, 1);
});

test("creation is serialized and OpenCode slots sort numerically", async () => {
  const app = await fixture();
  for (const role of ["oc-10", "oc-2", "nvim"]) await app.command(role);
  assert.equal(app.calls.length, 1);
  app.flush();
  assert.deepEqual(app.spaces[0].tabs.map((tab) => tab.name), ["nvim", "oc-2", "oc-10", "1"]);
  const editor = app.calls.find(([name, args]) => name === "tab.new" && args.name === "nvim")[1];
  assert.equal(editor.folder, "/project one");
  assert.deepEqual(editor.argv, ["exec", "env", "HERDR_APP_HOME=/config/herdr-app", "HERDR_APP_SPACE_ID=one", "herdr-app-vim", "--start"]);
  const opencode = app.calls.find(([name, args]) => name === "tab.new" && args.name === "oc-2")[1];
  assert.deepEqual(opencode.argv, ["exec", "env", "HERDR_APP_HOME=/config/herdr-app", "HERDR_APP_SPACE_ID=one",
    "herdr-app-opencode", "--start", "oc-2"]);
});

test("a space switch during creation does not redirect the new tab or steal focus", async () => {
  const app = await fixture();
  app.spaces[0].tabs.push({ id: "editor", name: "nvim", named: true });
  await app.command("shell");
  await app.command("nvim");
  app.spaces[0].active = false;
  app.spaces[1].active = true;
  app.flush();
  assert.equal(app.spaces[1].active, true);
  assert.equal(app.spaces[1].tabs.length, 1);
  assert.ok(app.calls.every(([name]) => name !== "tab.select"));
});

test("the opencode alias reuses its existing tab", async () => {
  const app = await fixture();
  app.spaces[0].tabs.push({ id: "old-agent", name: "opencode", named: true });
  await app.command("oc-1");
  assert.deepEqual(app.calls.map(([name]) => name), ["tab.rename", "tab.select"]);
});

test("unknown roles, stale spaces and check mode never create tabs", async () => {
  const app = await fixture();
  for (const command of ["1", "oc-0", "oc-01", "unknown", "shell@missing", "shell@one@two"]) await app.command(command);
  assert.deepEqual(app.calls, []);
  const check = await fixture(true);
  await check.command("nvim");
  assert.deepEqual(check.calls, []);
});

const projectCommand = (project) => `project@${encodeURIComponent(JSON.stringify(project))}`;

test("a project without a definition opens the fallback nvim tab", async () => {
  const app = await fixture();
  await app.command(projectCommand({ folder: "/no-config", label: "Default" }));
  app.flush();
  const space = app.spaces.find((space) => space.folder === "/no-config");
  assert.deepEqual(space.tabs.map((tab) => tab.name), ["nvim"]);
  assert.equal(space.selected, space.tabs[0].id);
  assert.equal(app.calls.filter(([name]) => name === "tab.new").length, 1);
});

test("a new project opens configured tabs in order, selects the first, and removes its bootstrap shell", async () => {
  const app = await fixture();
  app.files.set("/new project/herdr-project.json", '{"tabs":["oc-2","shell","nvim"]}');
  const command = projectCommand({ folder: "/new project", label: "New" });
  for (let i = 0; i < 5; i++) await app.command(command);
  app.flush();
  const space = app.spaces.find((space) => space.folder === "/new project");
  assert.deepEqual(space.tabs.map((tab) => tab.name), ["oc-2", "shell", "nvim"]);
  assert.equal(space.selected, space.tabs[0].id);
  assert.equal(app.calls.filter(([name]) => name === "space.new").length, 1);
  assert.equal(app.calls.filter(([name]) => name === "tab.new").length, 3);
  await app.command("oc-1");
  app.flush();
  assert.deepEqual(space.tabs.map((tab) => tab.name), ["oc-2", "shell", "nvim", "oc-1"]);
});

test("reopening a project fills missing tabs and preserves existing programs, extra tabs, and selection", async () => {
  const app = await fixture();
  const space = app.spaces[0];
  space.tabs.push({ id: "existing-editor", name: "nvim", named: true });
  space.selected = "original";
  app.files.set("/project one/herdr-project.json", '{"tabs":["shell","nvim"]}');
  const command = projectCommand({ id: "one", folder: "/project one", label: "Existing" });
  await app.command(command);
  app.flush();
  await app.command(command);
  app.flush();
  assert.deepEqual(space.tabs.map((tab) => tab.name), ["shell", "nvim", "1"]);
  assert.equal(space.tabs[1].id, "existing-editor");
  assert.equal(space.selected, "original");
  assert.equal(app.calls.filter(([name]) => name === "tab.new").length, 1);
  assert.equal(app.calls.filter(([name]) => name === "tab.close" || name === "space.new").length, 0);
});

test("invalid project definitions report their path and open just a default shell", async () => {
  const app = await fixture();
  app.files.set("/broken/herdr-project.json", '{"tabs":["nvim","oops"]}');
  await app.command(projectCommand({ folder: "/broken", label: "Broken" }));
  app.flush();
  assert.equal(app.calls.filter(([name]) => name === "tab.new").length, 0);
  assert.equal(app.spaces.find((space) => space.folder === "/broken").tabs.length, 1);
  assert.match(app.calls.find(([name]) => name === "notify")[1].body, /\/broken\/herdr-project\.json:.*oops/);
});

test("a stale project selection does not recreate a closed space", async () => {
  const app = await fixture();
  await app.command(projectCommand({ id: "closed", folder: "/gone", label: "Gone" }));
  app.flush();
  assert.deepEqual(app.calls, []);
});

test("the bootstrap shell stays until layout creation finishes, including a failed last tab", async () => {
  const app = await fixture();
  app.files.set("/new/herdr-project.json", '{"tabs":["shell","nvim"]}');
  app.failures.add("nvim");
  await app.command(projectCommand({ folder: "/new", label: "New" }));
  app.flush();
  const space = app.spaces.find((space) => space.folder === "/new");
  assert.deepEqual(space.tabs.map((tab) => tab.name), ["shell", "1"]);
  app.timers.at(-1)();
  app.flush();
  assert.deepEqual(space.tabs.map((tab) => tab.name), ["shell"]);
});

test("a rejected space creation does not block the next project request", async () => {
  const app = await fixture();
  app.failures.add("space.new");
  await app.command(projectCommand({ folder: "/failed", label: "Failed" }));
  app.flush();
  assert.match(app.calls.find(([name]) => name === "notify")[1].body, /space.new unavailable/);
  app.failures.clear();
  await app.command(projectCommand({ folder: "/next", label: "Next" }));
  app.flush();
  assert.ok(app.spaces.some((space) => space.folder === "/next"));
});

const creations = (app) => app.calls.filter(([name]) => name === "tab.new").map(([, args]) => args);
const devArgv = (...args) => ["exec", "env", "-u", "HERDR_ENV", "--", ...args];

test("project layouts use one validated dev configuration for the whole batch", async () => {
  const app = await fixture();
  const path = "/new/herdr-project.json";
  app.files.set(path, '{"tabs":["shell","dev"],"dev":["npm","run","dev","--","two words"]}');
  await app.command(projectCommand({ folder: "/new", label: "New" }));
  app.files.set(path, '{"dev":["changed"]}');
  app.flush();
  const space = app.spaces.find((space) => space.folder === "/new");
  assert.deepEqual(space.tabs.map((tab) => tab.name), ["shell", "dev"]);
  assert.deepEqual(creations(app).find((tab) => tab.name === "dev").argv, devArgv("npm", "run", "dev", "--", "two words"));
  assert.deepEqual(app.reads, [path]);
});

test("dev shortcuts reuse a running tab and reload the command only when recreating it", async () => {
  const app = await fixture();
  const path = "/project one/herdr-project.json";
  app.files.set(path, '{"dev":["npm","run","dev"]}');
  for (let i = 0; i < 10; i++) await app.command("dev");
  app.flush();
  assert.equal(creations(app).length, 1);
  assert.deepEqual(creations(app)[0].argv, devArgv("npm", "run", "dev"));
  assert.equal(creations(app)[0].folder, "/project one");
  app.files.set(path, "{");
  await app.command("dev");
  app.flush();
  assert.deepEqual(app.reads, [path], "Focusing a running dev does not read even a broken config");
  assert.ok(app.calls.every(([name]) => name !== "notify"));
  app.spaces[0].tabs = app.spaces[0].tabs.filter((tab) => tab.name !== "dev");
  app.files.set(path, '{"dev":["./dev script","new argument"]}');
  await app.command("dev");
  app.flush();
  assert.deepEqual(creations(app)[1].argv, devArgv("./dev script", "new argument"));
});

test("dev shortcuts use fallback commands, while a project file fully overrides them", async () => {
  for (const override of [false, true]) {
    const app = await fixture();
    app.files.set("/config/herdr-app/herdr-project.json", '{"dev":["npm","run","dev"]}');
    if (override) app.files.set("/project one/herdr-project.json", "{}");
    await app.command("dev");
    app.flush();
    assert.deepEqual(creations(app)[0].argv, override
      ? devArgv("zsh", "-ic", "if [[ -f Makefile ]]; then exec make dev; fi")
      : devArgv("npm", "run", "dev"));
  }
});

test("remote dev shortcuts read their own definitions and ignore local definitions", async () => {
  const app = await fixture();
  app.spaces[0].machine = "remote";
  app.files.set("/project one/herdr-project.json", '{"dev":["local-only"]}');
  app.files.set("remote:/project one/herdr-project.json", '{"dev":["remote-dev"]}');
  await app.command("dev");
  app.flush();
  assert.deepEqual(app.reads, ["/project one/herdr-project.json"]);
  assert.deepEqual(creations(app)[0].argv, devArgv("remote-dev"));
});

test("the same project path on two machines creates separate spaces with remote paths and config", async () => {
  const app = await fixture();
  app.files.set("vps:/project one/herdr-project.json", '{"tabs":["nvim","git","oc-1","dev"],"dev":["remote-dev"]}');
  await app.command(projectCommand({ folder: "/project one", label: "Local" }));
  await app.command(projectCommand({ folder: "/project one", label: "Remote", machine: "vps" }));
  app.flush();
  // The queued remote configuration is asynchronous.
  await new Promise(setImmediate);
  app.flush();
  const remote = app.spaces.find((space) => space.machine === "vps");
  assert.ok(remote);
  assert.deepEqual(remote.tabs.map((tab) => tab.name), ["nvim", "git", "oc-1", "dev"]);
  const tabs = creations(app).filter((tab) => tab.space === remote.id);
  assert.ok(tabs[0].argv.includes("HERDR_APP_HOME=/remote/app"));
  assert.ok(tabs[1].argv.includes("--use-config-file=/remote/home/.config/lazygit/config.yml,/remote/home/.config/lazygit/config-herdr-app.yml"));
  assert.ok(tabs[2].argv.includes("HERDR_APP_HOME=/remote/app"));
  assert.ok(tabs[2].argv.includes(`HERDR_APP_SPACE_ID=${remote.id.slice(4)}`));
  assert.deepEqual(tabs[3].argv, devArgv("remote-dev"));
  assert.equal(app.spaces.filter((space) => space.folder === "/project one").length, 2);
  const before = creations(app).length;
  await app.command(projectCommand({ folder: "/project one", machine: "vps" }));
  app.flush();
  assert.equal(creations(app).length, before);
});

test("invalid dev configuration prevents partial project layouts and shortcut launches", async () => {
  const app = await fixture();
  app.files.set("/broken/herdr-project.json", '{"tabs":["nvim","dev"],"dev":[]}');
  await app.command(projectCommand({ folder: "/broken", label: "Broken" }));
  app.flush();
  await app.command("dev");
  app.flush();
  assert.deepEqual(creations(app), []);
  assert.equal(app.spaces.find((space) => space.folder === "/broken").tabs.length, 1);
  assert.equal(app.calls.filter(([name]) => name === "notify").length, 2);
  assert.match(app.calls.find(([name]) => name === "notify")[1].body, /\/broken\/herdr-project\.json:.*"dev"/);
});

test("dev configuration reads recheck tabs, closed spaces, and focus before launching", async () => {
  for (const change of ["tab", "space", "focus"]) {
    const app = await fixture();
    let resolve;
    app.files.set("/project one/herdr-project.json", new Promise((done) => { resolve = done; }));
    await app.command("dev");
    await app.command("dev");
    if (change === "tab") app.spaces[0].tabs.push({ id: "external", name: "dev", named: true });
    if (change === "space") app.spaces.shift();
    if (change === "focus") {
      app.spaces[0].active = false;
      app.spaces[1].active = true;
    }
    app.render();
    resolve('{"dev":["npm","run","dev"]}');
    await new Promise(setImmediate);
    app.flush();
    assert.equal(creations(app).length, change === "focus" ? 1 : 0);
    if (change === "tab") assert.equal(app.spaces[0].selected, "external");
    if (change === "focus") {
      assert.equal(creations(app)[0].space, "one");
      assert.ok(app.calls.every(([name]) => name !== "tab.select"));
    }
  }
});

test("a failed dev read or rejected launch releases queued requests and permits retry", async () => {
  for (const failure of ["read", "launch"]) {
    const app = await fixture();
    let resolve, reject;
    const path = "/project one/herdr-project.json";
    app.files.set(path, new Promise((done, fail) => { resolve = done; reject = fail; }));
    await app.command("dev");
    await app.command("shell");
    if (failure === "read") reject(new Error("read failed"));
    else {
      app.failures.add("tab.new");
      resolve('{"dev":["npm","run","dev"]}');
    }
    await new Promise(setImmediate);
    app.failures.clear();
    app.flush();
    assert.ok(app.calls.some(([name]) => name === "notify"));
    assert.ok(creations(app).every((tab) => tab.name !== "dev"));
    if (failure === "read") assert.equal(creations(app)[0].name, "shell");
    app.files.set(path, '{"dev":["npm","run","dev"]}');
    await app.command("dev");
    app.flush();
    assert.equal(creations(app).at(-1).name, "dev");
  }
});
