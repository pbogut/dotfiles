import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";
import vm from "node:vm";

const root = new URL("../../../dot_config/herdr-app/mods/pbogut-tabs/", import.meta.url);
const setupHash = "a".repeat(64);

async function fixture(checking = false, initialTabs = [{ id: "original", name: "1", named: false }], marked = true) {
  const calls = [], commands = [], operations = [], timers = [], reads = [], overlays = [];
  const files = new Map(), persisted = new Map();
  files.set("/config/herdr-app/herdr-project.json", '{"tabs":["nvim"]}');
  const failures = new Set();
  const native = [], extraPanes = [], executions = [], setupChecks = new Map(), coreResults = new Map(), sends = [];
  const spaces = [
    { id: "one", active: true, folder: "/project one", tabs: initialTabs },
    { id: "two", active: false, folder: "/project two", tabs: [{ id: "other", name: "shell", named: true }] },
  ];
  if (marked) persisted.set("pbogut.projects.spaces", { one: true, two: true });
  const creation = {};
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
      checking: () => checking, spaces: () => structuredClone(spaces), terminals: () => structuredClone(native),
      hc: async (args) => {
        if (args[0] === "send") {
          sends.push({ terminal: args[1], command: args[2], spaces: structuredClone(spaces) });
          const terminal = native.find(terminal => terminal.address === args[1]);
          if (terminal) terminal.labels = {
            "pbogut.teardown": args[2].match(/'([^']+)'$/)[1], "pbogut.teardown.state": "running",
          };
          return { code: 0, stdout: "" };
        }
        return { code: 0, stdout: JSON.stringify(coreResults.get(args[1]) ??
          native.find(terminal => terminal.address === args[1])) };
      },
      panes: () => spaces.flatMap(space => space.tabs.filter(tab => tab.terminal)
        .map(tab => ({ tab: tab.id, terminal: tab.terminal }))).concat(extraPanes),
      exec: async (name, args, options) => {
        executions.push([name, [...args], { ...options }]);
        if (name === "env") {
          assert.deepEqual([...args.slice(0, 4)], ["HERDR_APP_HOME=/config/herdr-app", "herdr-app", "do", "space.new"]);
          if (failures.has("space.new")) throw new Error("space.new unavailable");
          const options = JSON.parse(args[4]);
          const id = `${options.machine ? `${options.machine}/` : ""}space-${++serial}`;
          calls.push(["space.new", options]);
          operations.push(["space.new", options, id]);
          creation.beforeReturn?.();
          return creation.reply ?? { code: 0, stdout: JSON.stringify({ space: id }), stderr: "" };
        }
        if (name === "bash") return setupChecks.get(`${options.on ?? ""}:${options.cwd}`)
          ?? { code: 75, stdout: `${setupHash}\n`, stderr: "" };
        return { code: 0, stdout: name === "sh" ? "/remote/home\n/remote/app\n" : `${options.cwd}/.bare\n` };
      },
      readTextFile: async (path, { on }) => {
        reads.push(path);
        return files.get(on ? `${on}:${path}` : path) ?? null;
      },
      shared: (key) => persisted.get(key),
      setShared: (key, value) => persisted.set(key, JSON.parse(JSON.stringify(value))),
      appHome: () => "/config/herdr-app", home: () => "/home/test",
      settings: () => ({ zoom: 1 }),
      notify: (args) => calls.push(["notify", args]),
      openOverlay: (args) => overlays.push(JSON.parse(JSON.stringify(args))),
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
    "./definition.js": new vm.SourceTextModule(await readFile(new URL("definition.js", root), "utf8"), { context }),
    "./hints.js": new vm.SourceTextModule(await readFile(new URL("hints.js", root), "utf8"), { context }),
    "./close.js": new vm.SourceTextModule(await readFile(new URL("close.js", root), "utf8"), { context }),
    "./tasks.js": new vm.SourceTextModule(await readFile(new URL("tasks.js", root), "utf8"), { context }),
  };
  const main = new vm.SourceTextModule(await readFile(new URL("main.js", root), "utf8"), { context });
  await main.link((name) => modules[name]);
  await main.evaluate();
  const cx = { spawn: (fn) => fn(cx), notify: () => view.render(cx), timer: { after: (_ms, fn) => timers.push(fn) } };
  let view = new main.namespace.default();
  view.init({}, cx);
  return {
    calls, spaces, timers, files, reads, overlays, failures, persisted, native, extraPanes, executions, setupChecks, coreResults, sends, creation,
    roles: modules["./roles.js"].namespace,
    render: () => view.render(cx),
    async confirm() {
      const overlay = overlays.pop();
      assert.equal(overlay?.mod, "confirm");
      await this.command(overlay.props.command.name.replace(/^pbogut-tabs\./, ""));
    },
    restart() {
      view = new main.namespace.default();
      view.init({}, cx);
    },
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
        for (const [name, args, created] of operations.splice(0)) {
          if (name === "space.new") {
            spaces.forEach((space) => { space.active = false; });
            const id = created;
            spaces.push({ id, folder: args.folder, name: args.name, machine: args.machine || null, active: true,
              tabs: [{ id: `${id}-initial`, name: "1", named: false, panes: 1 }] });
          } else if (name === "space.select") {
            spaces.forEach((space) => { space.active = space.id === args.id; });
          } else if (name === "space.close") {
            const index = spaces.findIndex(space => space.id === args.id);
            if (index >= 0) spaces.splice(index, 1);
          } else if (name === "tab.new") {
            if (failures.has(args.name)) continue;
            const tab = { id: `new-${++serial}`, name: args.name, named: true, panes: 1 };
            if (args.name === "setup" || args.name === "teardown") {
              tab.terminal = `terminal-${serial}`;
              native.push({ address: tab.terminal, labels: args.name === "teardown" ? {} : {
                [`pbogut.${args.name}`]: args.argv.at(-1), "pbogut.setup.hash": setupHash,
                [`pbogut.${args.name}.state`]: "running",
              } });
            }
            spaces.find((space) => space.id === args.space).tabs.push(tab);
          } else {
            const space = spaces.find((space) => space.tabs.some((tab) => tab.id === args.id));
            const index = space.tabs.findIndex((tab) => tab.id === args.id);
            if (name === "tab.move") space.tabs.splice(args.index - 1, 0, ...space.tabs.splice(index, 1));
            if (name === "tab.rename") space.tabs[index].name = args.name;
            if (name === "tab.close") space.tabs.splice(index, 1);
            if (name === "tab.select") {
              spaces.forEach((candidate) => { candidate.active = candidate === space; });
              space.tabs.forEach(tab => { tab.active = tab.id === args.id; });
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

test("last follows external selection per space, toggles and skips closed tabs", async () => {
  const app = await fixture(false, ["a", "b", "c"].map(id => ({ id, active: id === "a" })));
  const [one, two] = app.spaces;
  const select = (id) => one.tabs.forEach(tab => { tab.active = tab.id === id; });
  const toggle = async () => { await app.command("last"); app.flush(); };
  await toggle();
  assert.deepEqual(app.calls, []);
  select("b");
  app.render();
  select("c");
  await toggle(); // The command can arrive before the next render.
  assert.equal(one.selected, "b");
  one.active = false;
  two.active = true;
  two.tabs[0].active = true;
  app.render();
  app.calls.length = 0;
  await toggle();
  assert.deepEqual(app.calls, []);
  one.active = true;
  two.active = false;
  await toggle();
  assert.equal(one.selected, "c");
  one.tabs = one.tabs.filter(tab => tab.id !== "b");
  await toggle();
  assert.equal(one.selected, "a");
});

test("last-oc recalls a visited tab in this space while any of its panes runs OpenCode", async () => {
  const app = await fixture(false, ["shell", "oc-2", "oc-10", "scratch"].map(name =>
    ({ id: name, name, named: name !== "scratch", active: name === "shell" })));
  const [space, other] = app.spaces;
  const opencode = { key: "opencode" };
  const slotPane = { tab: "oc-10", program: opencode };
  app.extraPanes.push({ tab: "oc-2", program: opencode }, slotPane,
    { tab: "scratch", program: { key: "zsh" } }, { tab: "scratch", program: opencode });
  const visit = (id) => {
    space.tabs.forEach(tab => { tab.active = tab.id === id; });
    app.render();
  };
  const recall = async () => {
    app.calls.length = 0;
    await app.command("last-oc");
    app.flush();
    return app.calls;
  };
  assert.deepEqual(await recall(), []);
  visit("oc-2");
  visit("scratch");
  visit("oc-10");
  visit("shell");
  assert.deepEqual(await recall(), [["tab.select", { id: "oc-10" }]]);
  assert.deepEqual(await recall(), []);
  visit("shell");
  slotPane.program = { key: "zsh" };
  assert.deepEqual(await recall(), [["tab.select", { id: "scratch" }]]);
  visit("shell");
  space.active = false;
  other.active = true;
  other.tabs[0].active = true;
  assert.deepEqual(await recall(), []);
  space.active = true;
  other.active = false;
  space.tabs = space.tabs.filter(tab => tab.id !== "scratch");
  assert.deepEqual(await recall(), [["tab.select", { id: "oc-2" }]]);
});

test("loading the mod restores fixed order without changing existing tabs or selection", async () => {
  const tabs = ["oc-10", "shell", "nvim", "oc-2"].map(name => ({ id: name, name, named: true }));
  const app = await fixture(false, tabs);
  app.spaces[0].selected = "oc-10";
  app.flush();
  assert.deepEqual(app.spaces[0].tabs.map(tab => tab.name), ["nvim", "shell", "oc-2", "oc-10"]);
  assert.equal(app.spaces[0].selected, "oc-10");
  assert.ok(app.calls.every(([name]) => name === "tab.move"));
});

test("switching to a named tab preserves manual order until a new tab appears in that space", async () => {
  const app = await fixture(false, ["nvim", "git"].map(name => ({ id: name, name, named: true })));
  const [space, other] = app.spaces;
  space.tabs.reverse();
  app.render();
  await app.command("git");
  app.flush();
  assert.deepEqual(app.calls, [["tab.select", { id: "git" }]]);

  other.tabs.unshift({ id: "other-shell", named: false });
  app.render();
  app.flush();
  assert.deepEqual(other.tabs.map(tab => tab.id), ["other", "other-shell"]);
  assert.deepEqual(space.tabs.map(tab => tab.id), ["git", "nvim"]);

  space.tabs.splice(1, 0, { id: "plain", named: false });
  space.selected = "plain";
  app.render();
  app.flush();
  assert.deepEqual(space.tabs.map(tab => tab.id), ["nvim", "git", "plain"]);
  assert.equal(space.selected, "plain");
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
  assert.deepEqual(editor.argv, ["exec", "env", "HERDR_APP_HOME=/config/herdr-app", "HERDR_APP_SPACE_ID=one",
    "herdr-app-tab", "--start", "nvim", "herdr-app-vim", "--start"]);
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
  app.flush();
  assert.deepEqual(app.spaces[0].tabs.map(tab => tab.name), ["oc-1", "1"]);
  assert.equal(app.spaces[0].selected, "old-agent");
  assert.ok(app.calls.every(([name]) => ["tab.rename", "tab.move", "tab.select"].includes(name)));
});

test("unknown roles, stale spaces and check mode never create tabs", async () => {
  const app = await fixture();
  for (const command of ["1", "oc-0", "oc-01", "unknown", "shell@missing", "shell@one@two"]) await app.command(command);
  assert.deepEqual(app.calls, []);
  const check = await fixture(true);
  await check.command("nvim");
  assert.deepEqual(check.calls, []);
});

test("project task picker ignores ordinary spaces and reports empty or invalid definitions", async () => {
  const ordinary = await fixture(false, [], false);
  await ordinary.command("tasks");
  assert.deepEqual(ordinary.reads, []);
  assert.ok(ordinary.calls.some(([name, o]) => name === "notify" && /open a project/i.test(o.body)));
  const app = await fixture();
  await app.command("tasks");
  assert.ok(app.calls.some(([name, o]) => name === "notify" && /no tasks/i.test(o.body)));
  app.files.set("/project one/herdr-project.json", '{"tasks":"make test"}');
  await app.command("tasks");
  assert.ok(app.calls.some(([name, o]) => name === "notify" && o.body.includes("/project one/herdr-project.json")));
  assert.equal(app.overlays.length, 0);
});

const projectCommand = (project) => `project@${encodeURIComponent(JSON.stringify(project))}`;

test("ordinary spaces ignore project definitions and keep manual tool shortcuts and normal close", async () => {
  for (const machine of [null, "vps"]) {
    const app = await fixture(false, undefined, false);
    const space = app.spaces[0];
    space.machine = machine;
    const config = JSON.stringify({
      name: "Must not apply", tabs: ["sql"], dev: ["must-not-run"],
      setup: { script: "setup.sh" }, teardown: { script: "teardown.sh" },
    });
    for (const path of ["/project one/herdr-project.json", "/config/herdr-app/herdr-project.json", "/remote/app/herdr-project.json"]) {
      app.files.set(machine ? `${machine}:${path}` : path, config);
    }
    app.render();
    assert.deepEqual(app.calls, []);
    await app.command("reload-project");
    await app.command(projectCommand({ id: space.id, folder: space.folder, machine }));
    await app.command("dev");
    await settle(app);
    await app.command("nvim");
    await settle(app);
    assert.deepEqual(app.reads, [], "Neither project nor global herdr-project.json is read");
    assert.deepEqual(creations(app).map(tab => tab.name), ["dev", "nvim"]);
    assert.deepEqual(creations(app)[0].argv, devArgv(space, "zsh", "-ic", "if [[ -f Makefile ]]; then exec make dev; fi"));
    assert.equal(app.persisted.has("pbogut.projects.spaces"), false);
    app.calls.length = 0;
    await app.command("close-project");
    assert.deepEqual(app.calls, [["space.close", { id: space.id }]]);
    assert.deepEqual(app.reads, []);
    assert.ok(app.executions.every(([name]) => name !== "bash"), "No setup or teardown runs");
  }
});

test("only the CLI's returned space ID becomes a project, even beside ordinary spaces in the same folder", async () => {
  const app = await fixture(false, undefined, false);
  const ordinary = app.spaces[0];
  const originalTabs = structuredClone(ordinary.tabs);
  app.creation.beforeReturn = () => {
    app.spaces.unshift({ id: "concurrent", folder: ordinary.folder, machine: null, tabs: [] });
  };
  await app.command(projectCommand({ folder: ordinary.folder, label: "Project" }));
  app.flush();
  const project = app.spaces.find(space => space.id.startsWith("space-"));
  assert.deepEqual(app.persisted.get("pbogut.projects.spaces"), { [project.id]: true });
  assert.deepEqual(ordinary.tabs, originalTabs);
  assert.deepEqual(project.tabs.map(tab => tab.name), ["nvim"]);
  assert.equal(app.spaces.find(space => space.id === "concurrent").tabs.length, 0);
  app.restart();
  await app.command(projectCommand({ folder: ordinary.folder }));
  app.flush();
  assert.equal(app.calls.filter(([name]) => name === "space.new").length, 1, "A marked project is reused after a controller reload");
  assert.equal(project.active, true);
  app.spaces.splice(app.spaces.indexOf(project), 1);
  app.spaces.push({ id: "replacement", folder: ordinary.folder, tabs: [] });
  await app.command(projectCommand({ folder: ordinary.folder }));
  app.flush();
  assert.equal(app.calls.filter(([name]) => name === "space.new").length, 2);
  assert.equal(app.persisted.get("pbogut.projects.spaces").replacement, undefined);
  assert.equal(app.persisted.get("pbogut.projects.spaces").concurrent, undefined);
});

test("failed or incomplete CLI replies never infer a project ID from a directory", async () => {
  for (const reply of [
    { code: 1, stderr: "creation failed" },
    { code: 0, stdout: "{}" },
    { code: 0, stdout: "invalid JSON" },
  ]) {
    const app = await fixture(false, undefined, false);
    app.creation.reply = reply;
    await app.command(projectCommand({ folder: "/project one" }));
    app.flush();
    assert.equal(app.persisted.has("pbogut.projects.spaces"), false);
    assert.deepEqual(creations(app), []);
    assert.ok(app.calls.some(([name]) => name === "notify"));
    assert.equal(app.calls.filter(([name]) => name === "space.new").length, 1, "No automatic retry");
  }
});

test("a project without a definition opens the fallback nvim tab", async () => {
  const app = await fixture();
  await app.command(projectCommand({ folder: "/no-config", label: "Default" }));
  app.flush();
  const space = app.spaces.find((space) => space.folder === "/no-config");
  assert.deepEqual(space.tabs.map((tab) => tab.name), ["nvim"]);
  assert.equal(space.selected, space.tabs[0].id);
  assert.equal(app.calls.filter(([name]) => name === "tab.new").length, 1);
});

test("a project opens only configured tabs in fixed order and later shortcuts use that same order", async () => {
  const app = await fixture();
  app.files.set("/new project/herdr-project.json", '{"tabs":["oc-2","shell","nvim"]}');
  const command = projectCommand({ folder: "/new project", label: "New" });
  for (let i = 0; i < 5; i++) await app.command(command);
  app.flush();
  const space = app.spaces.find((space) => space.folder === "/new project");
  assert.deepEqual(space.tabs.map((tab) => tab.name), ["nvim", "shell", "oc-2"]);
  assert.equal(space.selected, space.tabs.find(tab => tab.name === "oc-2").id);
  assert.equal(app.calls.filter(([name]) => name === "space.new").length, 1);
  assert.equal(app.calls.filter(([name]) => name === "tab.new").length, 3);
  await app.command("oc-1");
  app.flush();
  assert.deepEqual(space.tabs.map((tab) => tab.name), ["nvim", "shell", "oc-1", "oc-2"]);
  assert.equal(app.persisted.get("pbogut.projects.spaces")[space.id], true);
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
  assert.deepEqual(space.tabs.map((tab) => tab.name), ["nvim", "shell", "1"]);
  assert.equal(space.tabs[0].id, "existing-editor");
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
const devArgv = (space, ...args) => ["exec", "env",
  `HERDR_APP_HOME=${space.machine ? "/remote/app" : "/config/herdr-app"}`,
  `HERDR_APP_SPACE_ID=${space.id.replace(/^[^/]+\//, "")}`,
  "herdr-app-tab", "--start", "dev", "env", "-u", "HERDR_ENV", "--", ...args];

test("manual reload applies fresh tabs and dev, refreshes labels, and preserves running tabs and selection", async () => {
  const app = await fixture();
  const space = app.spaces[0];
  space.selected = "original";
  const path = "/project one/herdr-project.json";
  app.files.set(path, '{"name":"First","tabs":["shell","dev"],"dev":["old-dev"]}');
  await app.command("reload-project");
  app.flush();
  const dev = space.tabs.find(tab => tab.name === "dev");
  app.files.set(path, '{"name":"Second","tabs":["dev","nvim"],"dev":["new-dev"]}');
  await app.command("reload-project");
  app.flush();
  assert.deepEqual(space.tabs.map(tab => tab.name), ["nvim", "shell", "dev", "1"]);
  assert.equal(space.tabs[2].id, dev.id);
  assert.equal(space.selected, "original");
  assert.equal(creations(app).filter(tab => tab.name === "dev").length, 1);
  assert.ok(app.calls.every(([name]) => !["tab.close", "space.select", "tab.select"].includes(name)));
  const updates = app.calls.filter(([name]) => name.startsWith("pbogut-spaces.reload@"));
  assert.equal(updates.length, 2);
  assert.deepEqual(JSON.parse(decodeURIComponent(updates[1][0].split("@")[1])),
    { folder: space.folder, machine: null });
  space.tabs = space.tabs.filter(tab => tab.id !== dev.id);
  await app.command("reload-project");
  app.flush();
  assert.deepEqual(creations(app).at(-1).argv, devArgv(space, "new-dev"));
});

test("invalid reloads and picker reopens preserve existing tabs and never refresh labels", async () => {
  const app = await fixture();
  const space = app.spaces[0];
  const path = "/project one/herdr-project.json";
  app.files.set(path, '{"tabs":["shell","dev"],"dev":["valid"]}');
  await app.command("reload-project");
  app.flush();
  const tabs = structuredClone(space.tabs);
  for (const [command, source] of [
    ["reload-project", "{"],
    ["reload-project", '{"name":"Wrong","tabs":["nvim"],"dev":[]}'],
    [projectCommand({ id: space.id, folder: space.folder }), '{"tabs":["unknown"]}'],
  ]) {
    app.calls.length = 0;
    app.files.set(path, source);
    await app.command(command);
    app.flush();
    assert.deepEqual(space.tabs, tabs);
    assert.ok(app.calls.some(([name]) => name === "notify"));
    assert.ok(app.calls.every(([name]) => !name.startsWith("pbogut-spaces.") && !name.startsWith("tab.")));
  }
});

test("empty project definitions and stale saved orders cannot override fixed sorting", async () => {
  const app = await fixture();
  const space = app.spaces[0];
  app.persisted.set("pbogut-tabs.order.one", ["oc-10", "shell", "nvim"]);
  space.tabs = ["oc-10", "shell", "nvim"].map(name => ({ id: name, name, named: true }));
  space.selected = "oc-10";
  app.files.set("/project one/herdr-project.json", '{"tabs":[]}');
  await app.command("reload-project");
  app.flush();
  assert.deepEqual(space.tabs.map(tab => tab.name), ["nvim", "shell", "oc-10"]);
  assert.equal(space.selected, "oc-10");
  assert.equal(creations(app).length, 0);
  await app.command("oc-2");
  app.flush();
  assert.deepEqual(space.tabs.map(tab => tab.name), ["nvim", "shell", "oc-2", "oc-10"]);
});

test("manual reload reads the active machine and a folderless space reports an error", async () => {
  const app = await fixture();
  app.spaces[0].machine = "remote";
  app.files.set("/project one/herdr-project.json", '{"tabs":["nvim"]}');
  app.files.set("remote:/project one/herdr-project.json", '{"tabs":["dev"],"dev":["remote-dev"]}');
  await app.command("reload-project");
  app.flush();
  assert.deepEqual(creations(app).map(tab => tab.name), ["dev"]);
  assert.deepEqual(creations(app)[0].argv, devArgv(app.spaces[0], "remote-dev"));
  const update = app.calls.find(([name]) => name.startsWith("pbogut-spaces.reload@"))[0];
  assert.equal(JSON.parse(decodeURIComponent(update.split("@")[1])).machine, "remote");
  app.calls.length = 0;
  delete app.spaces[0].folder;
  await app.command("reload-project");
  assert.deepEqual(app.calls.map(([name]) => name), ["notify"]);
});

test("project layouts use one validated dev configuration for the whole batch", async () => {
  const app = await fixture();
  const path = "/new/herdr-project.json";
  app.files.set(path, '{"tabs":["shell","dev"],"dev":["npm","run","dev","--","two words"]}');
  await app.command(projectCommand({ folder: "/new", label: "New" }));
  app.files.set(path, '{"dev":["changed"]}');
  app.flush();
  const space = app.spaces.find((space) => space.folder === "/new");
  assert.deepEqual(space.tabs.map((tab) => tab.name), ["shell", "dev"]);
  assert.deepEqual(creations(app).find((tab) => tab.name === "dev").argv, devArgv(space, "npm", "run", "dev", "--", "two words"));
  assert.deepEqual(app.reads, [path]);
});

test("dev shortcuts reuse a running tab and reload the command only when recreating it", async () => {
  const app = await fixture();
  const path = "/project one/herdr-project.json";
  app.files.set(path, '{"dev":["npm","run","dev"]}');
  for (let i = 0; i < 10; i++) await app.command("dev");
  app.flush();
  assert.equal(creations(app).length, 1);
  assert.deepEqual(creations(app)[0].argv, devArgv(app.spaces[0], "npm", "run", "dev"));
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
  assert.deepEqual(creations(app)[1].argv, devArgv(app.spaces[0], "./dev script", "new argument"));
});

test("dev shortcuts use fallback commands, while a project file fully overrides them", async () => {
  for (const override of [false, true]) {
    const app = await fixture();
    app.files.set("/config/herdr-app/herdr-project.json", '{"dev":["npm","run","dev"]}');
    if (override) app.files.set("/project one/herdr-project.json", "{}");
    await app.command("dev");
    app.flush();
    assert.deepEqual(creations(app)[0].argv, override
      ? devArgv(app.spaces[0], "zsh", "-ic", "if [[ -f Makefile ]]; then exec make dev; fi")
      : devArgv(app.spaces[0], "npm", "run", "dev"));
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
  assert.deepEqual(creations(app)[0].argv, devArgv(app.spaces[0], "remote-dev"));
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
  assert.deepEqual(remote.tabs.map((tab) => tab.name), ["nvim", "dev", "git", "oc-1"]);
  const tabs = creations(app).filter((tab) => tab.space === remote.id);
  assert.ok(tabs[0].argv.includes("HERDR_APP_HOME=/remote/app"));
  assert.ok(tabs[1].argv.includes("--use-config-file=/remote/home/.config/lazygit/config.yml,/remote/home/.config/lazygit/config-herdr-app.yml"));
  assert.ok(tabs[2].argv.includes("HERDR_APP_HOME=/remote/app"));
  assert.ok(tabs[2].argv.includes(`HERDR_APP_SPACE_ID=${remote.id.slice(4)}`));
  assert.deepEqual(tabs[3].argv, devArgv(remote, "remote-dev"));
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

const withSetup = () => JSON.stringify({
  tabs: ["shell", "dev"], dev: ["custom-dev"], setup: { script: "setup's script.sh" },
});
const settle = async (app) => {
  app.flush();
  await new Promise(setImmediate);
  app.flush();
};
function setupResult(app, space, state) {
  const tab = space.tabs.find(tab => tab.name === "setup");
  app.native.find(terminal => terminal.address === tab.terminal).labels["pbogut.setup.state"] = state;
  if (state === "success") space.tabs = space.tabs.filter(candidate => candidate !== tab);
  app.render();
  app.flush();
}

test("setup gates a new project's tabs while other spaces remain usable", async () => {
  const app = await fixture();
  app.files.set("/new/herdr-project.json", withSetup());
  const command = projectCommand({ folder: "/new" });
  await app.command(command);
  await settle(app);
  const space = app.spaces.find(space => space.folder === "/new");
  assert.deepEqual(space.tabs.map(tab => tab.name), ["1", "setup"]);
  await app.command(command);
  await settle(app);
  assert.equal(creations(app).filter(tab => tab.name === "setup").length, 1);
  await app.command("shell-3@two");
  app.flush();
  assert.equal(app.spaces[1].active, true);
  setupResult(app, space, "success");
  assert.deepEqual(space.tabs.map(tab => tab.name), ["shell", "dev"]);
  assert.equal(app.spaces[1].active, true, "Finishing setup never steals another space's focus");
});

test("failed setup keeps its output and retry replaces only the managed failed tab", async () => {
  const app = await fixture();
  const space = app.spaces[0];
  space.tabs.push({ id: "user-setup", name: "setup", named: true, panes: 1 });
  app.files.set("/project one/herdr-project.json", withSetup());
  await app.command("reload-project");
  await settle(app);
  const managed = space.tabs.find(tab => tab.name === "setup" && tab.terminal);
  app.native[0].labels["pbogut.setup.state"] = "failed";
  app.render();
  app.flush();
  assert.ok(space.tabs.includes(managed));
  assert.ok(!space.tabs.some(tab => tab.name === "dev"));
  await app.command("reload-project");
  await settle(app);
  assert.ok(space.tabs.some(tab => tab.id === "user-setup"));
  assert.ok(!space.tabs.some(tab => tab.id === managed.id));
  assert.equal(creations(app).filter(tab => tab.name === "setup").length, 2);
});

test("saved setup completion skips the setup tab and remote checks use remote paths", async () => {
  const app = await fixture();
  app.spaces[0].machine = "vps";
  app.files.set("vps:/project one/herdr-project.json", withSetup());
  app.setupChecks.set("vps:/project one", { code: 0 });
  await app.command("reload-project");
  await settle(app);
  assert.deepEqual(creations(app).map(tab => tab.name), ["shell", "dev"]);
  const check = app.executions.find(([name]) => name === "bash");
  assert.deepEqual(check[1].slice(0, 5), ["/remote/app/mods/pbogut-tabs/setup.sh", "check",
    "/remote/app", "/project one", "setup's script.sh"]);
  assert.deepEqual(check[2], { cwd: "/project one", on: "vps" });
});

test("closing a project during the setup check prevents a stale launch", async () => {
  const app = await fixture();
  let resolve;
  app.files.set("/project one/herdr-project.json", withSetup());
  app.setupChecks.set(":/project one", new Promise(done => { resolve = done; }));
  await app.command("reload-project");
  app.spaces.shift();
  app.render();
  resolve({ code: 75, stderr: "" });
  await settle(app);
  assert.deepEqual(creations(app), []);
});

test("closing setup before success prevents the layout and leaves retry available", async () => {
  const app = await fixture();
  app.files.set("/project one/herdr-project.json", withSetup());
  await app.command("reload-project");
  await settle(app);
  app.spaces[0].tabs = app.spaces[0].tabs.filter(tab => tab.name !== "setup");
  app.render();
  await settle(app);
  assert.ok(!creations(app).some(tab => tab.name === "dev"));
  assert.match(app.calls.find(([name]) => name === "notify")[1].body, /interrupted/);
  await app.command("reload-project");
  await settle(app);
  assert.equal(creations(app).filter(tab => tab.name === "setup").length, 2);
});

test("successful setup returns to the previous tab unless the user changed selection", async () => {
  for (const changed of [false, true]) {
    const app = await fixture();
    const space = app.spaces[0];
    space.tabs[0].active = true;
    space.selected = "original";
    app.files.set("/project one/herdr-project.json", withSetup());
    await app.command("reload-project");
    await settle(app);
    assert.equal(space.tabs.find(tab => tab.name === "setup").id, space.selected);
    if (changed) {
      await app.command("shell-3");
      app.flush();
    }
    const expected = changed ? space.selected : "original";
    setupResult(app, space, "success");
    assert.equal(space.selected, expected);
  }
});

test("reopening adopts a live setup and rechecks changed or legacy hashes after it finishes", async () => {
  for (const hash of [setupHash, "b".repeat(64), null]) {
    const app = await fixture(false, [
      { id: "original", name: "1", named: false },
      { id: "surviving", name: "setup", named: true, panes: 1, terminal: "surviving-terminal" },
    ]);
    app.native.push({ address: "surviving-terminal", labels: {
      "pbogut.setup": "old-attempt", "pbogut.setup.state": "running",
      ...(hash ? { "pbogut.setup.hash": hash } : { "pbogut.setup.version": "1" }),
    } });
    app.files.set("/project one/herdr-project.json", withSetup());
    await app.command("reload-project");
    await settle(app);
    assert.deepEqual(creations(app), [], "Do not start another hook while the previous one runs");
    setupResult(app, app.spaces[0], "success");
    await settle(app);
    assert.deepEqual(creations(app).map(tab => tab.name), hash === setupHash ? ["shell", "dev"] : ["setup"]);
  }
});

test("an unreadable setup script reports the check failure and permits retry", async () => {
  const app = await fixture();
  app.files.set("/project one/herdr-project.json", withSetup());
  app.setupChecks.set(":/project one", { code: 1, stderr: "setup's script.sh: No such file or directory" });
  await app.command("reload-project");
  await settle(app);
  assert.deepEqual(creations(app), []);
  assert.match(app.calls.find(([name]) => name === "notify")[1].body, /No such file or directory/);
  app.setupChecks.clear();
  await app.command("reload-project");
  await settle(app);
  assert.deepEqual(creations(app).map(tab => tab.name), ["setup"]);
});

const withTeardown = (script = "cleanup's script.sh") => JSON.stringify({ tabs: ["dev"], teardown: { script } });
function teardownResult(app, space, state) {
  const tab = space.tabs.find(tab => tab.name === "teardown" && tab.terminal);
  app.native.find(terminal => terminal.address === tab.terminal).labels["pbogut.teardown.state"] = state;
  if (state === "success") space.tabs = space.tabs.filter(candidate => candidate !== tab);
  app.render();
  app.flush();
}

test("Close project without a teardown closes only the requested space", async () => {
  const app = await fixture();
  await app.command("close-project@two");
  assert.deepEqual(app.calls, []);
  assert.equal(app.overlays.at(-1).props.title, "Close project?");
  assert.equal(app.overlays.at(-1).props.detail, "");
  await app.confirm();
  app.flush();
  assert.deepEqual(app.spaces.map(space => space.id), ["one"]);
  assert.deepEqual(creations(app), []);
  assert.deepEqual(app.calls, [["space.close", { id: "two", confirmed: true }]]);
});

test("project confirmation leaves tabs untouched until accepted and can be cancelled and reopened", async () => {
  for (const teardown of [false, true]) {
    const app = await fixture();
    app.files.set("/project one/herdr-project.json", teardown ? withTeardown() : "{}");
    const before = structuredClone(app.spaces);
    await app.command("close-project");
    await settle(app);
    assert.deepEqual(app.spaces, before);
    assert.deepEqual(app.calls, []);
    assert.deepEqual(app.sends, []);
    const prompt = app.overlays.pop();
    assert.equal(prompt.props.title, "Close project?");
    assert.equal(prompt.props.detail, teardown ? "The configured teardown will run before the project closes." : "");
    // Cancel/Esc dismisses the native overlay without running its command.
    await app.command("close-project");
    await app.confirm();
    await settle(app);
    if (teardown) assert.equal(app.sends.length, 1);
    else assert.deepEqual(app.spaces.map(space => space.id), ["two"]);
  }
});

test("confirmation keeps its project target after a space switch and ignores a closed target", async () => {
  for (const removed of [false, true]) {
    const app = await fixture();
    await app.command("close-project");
    app.spaces[0].active = false;
    app.spaces[1].active = true;
    if (removed) app.spaces.shift();
    app.render();
    await app.confirm();
    await settle(app);
    assert.deepEqual(app.spaces.map(space => space.id), ["two"]);
    assert.equal(app.spaces[0].active, true);
    assert.equal(app.calls.filter(([name]) => name === "space.close").length, removed ? 0 : 1);
  }
});

test("confirming a project close rechecks setup before touching tabs", async () => {
  const app = await fixture();
  await app.command("close-project");
  app.spaces[0].tabs.push({ id: "setup", name: "setup", named: true, terminal: "setup-terminal" });
  app.native.push({ address: "setup-terminal", labels: {
    "pbogut.setup": "new-setup", "pbogut.setup.state": "running",
  } });
  await app.confirm();
  await settle(app);
  assert.equal(app.spaces.length, 2);
  assert.ok(app.calls.some(([name, args]) => name === "notify" && args.title === "Project setup is running"));
  assert.ok(app.calls.every(([name]) => name !== "space.close" && name !== "tab.close"));
});

test("teardown runs only on explicit close and success closes its original space", async () => {
  const app = await fixture();
  const space = app.spaces[0];
  app.files.set("/project one/herdr-project.json", withTeardown());
  await app.command("reload-project");
  app.flush();
  assert.ok(creations(app).every(tab => tab.name !== "teardown"));
  for (let i = 0; i < 5; i++) await app.command("close-project");
  await app.confirm();
  await settle(app);
  assert.deepEqual(app.sends[0].spaces[0].tabs.map(tab => tab.name), ["teardown"]);
  assert.deepEqual(app.sends[0].spaces[1].tabs.map(tab => tab.id), ["other"]);
  assert.equal(creations(app).filter(tab => tab.name === "teardown").length, 1);
  await app.command("reload-project");
  await app.command("nvim");
  app.flush();
  const editor = space.tabs.find(tab => tab.name === "nvim");
  assert.ok(editor, "Named-tab shortcuts can launch programs during teardown");
  assert.equal(space.selected, editor.id);
  await app.command("shell");
  app.flush();
  await app.command("nvim");
  app.flush();
  assert.equal(space.selected, editor.id, "Existing named tabs can be focused during teardown");
  assert.equal(creations(app).filter(tab => tab.name === "nvim").length, 1);
  await app.command("shell@two");
  app.flush();
  teardownResult(app, space, "success");
  assert.deepEqual(app.spaces.map(space => space.id), ["two"]);
  assert.equal(app.spaces[0].active, true);
});

test("teardown closes all previous tabs before its script and retries after failure", async () => {
  const app = await fixture();
  const space = app.spaces[0];
  space.tabs.push({ id: "user-teardown", name: "teardown", named: true, panes: 1 });
  app.files.set("/project one/herdr-project.json", withTeardown());
  await app.command("close-project");
  await app.confirm();
  await settle(app);
  const first = space.tabs.find(tab => tab.name === "teardown" && tab.terminal);
  teardownResult(app, space, "failed");
  assert.ok(app.spaces.includes(space));
  assert.ok(space.tabs.includes(first));
  assert.deepEqual(space.tabs.map(tab => tab.id), [first.id]);
  assert.deepEqual(app.sends[0].spaces[0].tabs.map(tab => tab.id), [first.id]);
  app.files.set("/project one/herdr-project.json", withTeardown("fixed.sh"));
  await app.command("close-project");
  await app.confirm();
  await settle(app);
  assert.ok(!space.tabs.some(tab => tab.id === "user-teardown"));
  assert.ok(!space.tabs.some(tab => tab.id === first.id));
  assert.match(app.sends.at(-1).command, /'fixed.sh'/);
  teardownResult(app, space, "success");
  assert.ok(!app.spaces.includes(space));
});

test("invalid close configuration leaves the space intact and can be corrected", async () => {
  const app = await fixture();
  app.files.set("/project one/herdr-project.json", '{"teardown":{}}');
  await app.command("close-project");
  app.flush();
  assert.equal(app.spaces.length, 2);
  assert.deepEqual(creations(app), []);
  assert.match(app.calls.find(([name]) => name === "notify")[1].body, /\/project one\/herdr-project\.json:.*teardown/);
  app.files.set("/project one/herdr-project.json", "{}");
  await app.command("close-project");
  await app.confirm();
  app.flush();
  assert.deepEqual(app.spaces.map(space => space.id), ["two"]);
});

test("a rejected sibling-tab close prevents teardown from starting and permits retry", async () => {
  const app = await fixture();
  app.files.set("/project one/herdr-project.json", withTeardown());
  app.failures.add("tab.close");
  await app.command("close-project");
  await app.confirm();
  await settle(app);
  assert.deepEqual(app.sends, []);
  assert.ok(app.spaces[0].tabs.some(tab => tab.id === "original"));
  assert.match(app.calls.find(([name]) => name === "notify")[1].body, /tab.close unavailable/);
  app.failures.clear();
  await app.command("close-project");
  await app.confirm();
  await settle(app);
  assert.equal(app.sends.length, 1);
  assert.deepEqual(app.sends[0].spaces[0].tabs.map(tab => tab.name), ["teardown"]);
});

test("remote teardown uses its own fallback paths and project overrides remain authoritative", async () => {
  for (const override of [true, false]) {
    const app = await fixture();
    app.spaces[0].machine = "vps";
    app.files.set("vps:/remote/app/herdr-project.json", withTeardown());
    app.files.set("/project one/herdr-project.json", withTeardown("local-only"));
    if (override) app.files.set("vps:/project one/herdr-project.json", "{}");
    await app.command("close-project");
    await app.confirm();
    await settle(app);
    if (override) assert.deepEqual(creations(app), []);
    else assert.ok(app.sends[0].command.startsWith(
      "'exec' 'bash' '/remote/app/mods/pbogut-tabs/teardown.sh' '/remote/app' 'cleanup'\\''s script.sh' "));
  }
});

test("delayed close reads keep their original target and ignore an already closed space", async () => {
  for (const removed of [true, false]) {
    const app = await fixture();
    let resolve;
    app.files.set("/project one/herdr-project.json", new Promise(done => { resolve = done; }));
    await app.command("close-project");
    app.spaces[0].active = false;
    app.spaces[1].active = true;
    if (removed) app.spaces.shift();
    app.render();
    resolve(withTeardown());
    await settle(app);
    if (!removed) {
      await app.confirm();
      await settle(app);
    }
    assert.equal(creations(app).length, removed ? 0 : 1);
    assert.ok(app.calls.every(([name]) => name !== "tab.select"));
    if (!removed) assert.equal(creations(app)[0].space, "one");
  }
});

test("closing the teardown tab keeps the space, while a late success still closes it", async () => {
  for (const success of [true, false]) {
    const app = await fixture();
    const space = app.spaces[0];
    app.files.set("/project one/herdr-project.json", withTeardown());
    await app.command("close-project");
    await app.confirm();
    await settle(app);
    const tab = space.tabs.find(tab => tab.name === "teardown");
    space.tabs = space.tabs.filter(candidate => candidate !== tab);
    if (success) app.coreResults.set(tab.terminal, { labels: { "pbogut.teardown.state": "success" } });
    app.render();
    await settle(app);
    assert.equal(app.spaces.includes(space), !success);
    if (!success) {
      assert.match(app.calls.find(([name]) => name === "notify")[1].body, /interrupted/);
      await app.command("close-project");
      await app.confirm();
      await settle(app);
      assert.equal(creations(app).length, 2);
    }
  }
});

test("Close project adopts surviving teardown and waits for a running setup", async () => {
  for (const kind of ["setup", "teardown"]) {
    const app = await fixture(false, [
      { id: "original", name: "1", named: false },
      { id: "survivor", name: kind, named: true, panes: 1, terminal: "survivor-terminal" },
    ]);
    app.native.push({ address: "survivor-terminal", labels: {
      [`pbogut.${kind}`]: "old-attempt", [`pbogut.${kind}.state`]: "running",
    } });
    await app.command("close-project");
    await settle(app);
    assert.deepEqual(app.reads, []);
    assert.deepEqual(creations(app), []);
    if (kind === "teardown") {
      teardownResult(app, app.spaces[0], "success");
      assert.deepEqual(app.spaces.map(space => space.id), ["two"]);
    } else assert.ok(app.calls.some(([name, args]) => name === "notify" && /setup is running/.test(args.title)));
  }
});

test("fast teardown is identified by its pane before any labels reach the App", async () => {
  const app = await fixture();
  const space = app.spaces[0];
  space.machine = "vps";
  app.files.set("vps:/project one/herdr-project.json", withTeardown());
  app.failures.add("teardown");
  await app.command("close-project");
  await app.confirm();
  app.flush();
  const tab = { id: "fast", name: "teardown", named: true, panes: 1, terminal: "vps/fast-terminal" };
  space.tabs.push(tab);
  app.render();
  app.flush();
  space.tabs = space.tabs.filter(candidate => candidate !== tab);
  app.coreResults.set(tab.terminal, { labels: { "pbogut.teardown.state": "success" } });
  app.render();
  await settle(app);
  assert.deepEqual(app.spaces.map(space => space.id), ["two"]);
  assert.ok(app.calls.every(([name]) => name !== "notify"));
});
