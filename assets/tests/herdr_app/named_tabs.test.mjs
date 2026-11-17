import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";
import vm from "node:vm";

const root = new URL("../../../dot_config/herdr-app/mods/pbogut-tabs/", import.meta.url);

async function fixture(checking = false) {
  const calls = [], commands = [], operations = [], timers = [];
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
      appHome: () => "/config/herdr-app", home: () => "/home/test",
      notify: (args) => calls.push(["notify", args]),
      nextCommand: () => commands.length ? Promise.resolve(commands.shift())
        : new Promise((resolve) => { receive = resolve; }),
      run: (name, args) => {
        const operation = [name, JSON.parse(JSON.stringify(args))];
        calls.push(operation);
        operations.push(operation);
      },
    }),
    "./roles.js": new vm.SourceTextModule(await readFile(new URL("roles.js", root), "utf8"), { context }),
  };
  const main = new vm.SourceTextModule(await readFile(new URL("main.js", root), "utf8"), { context });
  await main.link((name) => modules[name]);
  await main.evaluate();
  const cx = { spawn: (fn) => fn(cx), timer: { after: (_ms, fn) => timers.push(fn) } };
  const view = new main.namespace.default();
  view.init({}, cx);
  return {
    calls, spaces, timers,
    roles: modules["./roles.js"].namespace,
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
          if (name === "tab.new") {
            spaces.find((space) => space.id === args.space).tabs.push({ id: `new-${++serial}`, name: args.name, named: true });
          } else {
            const space = spaces.find((space) => space.tabs.some((tab) => tab.id === args.id));
            const index = space.tabs.findIndex((tab) => tab.id === args.id);
            if (name === "tab.move") space.tabs.splice(args.index - 1, 0, ...space.tabs.splice(index, 1));
            if (name === "tab.rename") space.tabs[index].name = args.name;
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
