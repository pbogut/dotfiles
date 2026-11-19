import assert from "node:assert/strict";
import { test } from "node:test";
import { loadProjectConfig, projectConfig, projectTabs } from "../../../dot_config/herdr-app/mods/pbogut-tabs/project.js";
import { commandFor, compareTabs } from "../../../dot_config/herdr-app/mods/pbogut-tabs/roles.js";

const defaults = "/config/herdr-app/herdr-project.json";
const loadProjectTabs = async (...args) => (await loadProjectConfig(...args)).tabs;

test("task definitions validate the entire file and preserve literal command arguments", async () => {
  const task = { name: "docs @ staging", command: ["./run docs", "$1", "", "'"] };
  assert.deepEqual(projectConfig({ tasks: [task] }).tasks, [{ ...task, hint: "f", progress: false, close: false }]);
  assert.deepEqual(projectConfig({ tasks: [] }).tasks, []);
  for (const tasks of [null, {}, [task, task], [null], [{ ...task, name: " shell" }],
    [{ ...task, name: "oc-2" }], [{ ...task, name: "setup" }], [{ ...task, command: [] }],
    [{ ...task, command: "make test" }], [{ ...task, progress: "yes" }], [{ ...task, close: null }]]) {
    await assert.rejects(loadProjectConfig("/repo/main", async () => ({ code: 0, stdout: "/repo/.bare\n" }),
      async () => JSON.stringify({ tasks }), defaults), /\/repo\/herdr-project.json:.*tasks/);
  }
});

test("custom task hints accept lowercase letters and reject ambiguous shortcuts", () => {
  const make = (name, hint) => ({ name, hint, command: ["true"] });
  assert.equal(projectConfig({ tasks: [make("check", "bt")] }).tasks[0].hint, "bt");
  for (const bad of ["", "S", "s a", "1", "s\n", null, 7]) {
    assert.throws(() => projectConfig({ tasks: [make("check", bad)] }), /hint.*check.*lowercase/);
  }
  for (const [a, b] of [["s", "sa"], ["sa", "s"], ["sa", "sa"]]) {
    assert.throws(() => projectConfig({ tasks: [make("first", a), make("second", b)] }), /second.*conflicts with.*first/);
  }
});

test("teardown validates its script and follows whole-file fallback precedence", async () => {
  const teardown = { script: "scripts/cleanup project's.sh" };
  assert.deepEqual(projectConfig({ teardown }), { tabs: [], teardown });
  for (const value of [null, [], "cleanup.sh", {}, { script: "" }, { script: " " },
    { script: 1 }, { script: "bad\0path" }]) assert.throws(() => projectConfig({ teardown: value }), /"teardown"/);
  const exec = async () => ({ code: 0, stdout: "/repo/.bare\n" });
  for (const local of [true, false]) {
    const config = await loadProjectConfig("/repo/main", exec,
      async (path) => path === (local ? "/repo/herdr-project.json" : defaults) ? JSON.stringify({ teardown }) : null, defaults);
    assert.deepEqual(config.teardown, { ...teardown, directory: local ? "/repo" : "/config/herdr-app" });
  }
  assert.deepEqual(await loadProjectConfig("/repo/main", exec,
    async (path) => path === defaults ? JSON.stringify({ teardown }) : "{}", defaults), { tabs: [] });
  await assert.rejects(loadProjectConfig("/repo/main", exec,
    async () => '{"teardown":{}}', defaults), /\/repo\/herdr-project\.json:.*"teardown"/);
});

test("setup requires a script and resolves from the selected definition", async () => {
  const setup = { script: "scripts/setup project's.sh" };
  assert.deepEqual(projectConfig({ setup }), { tabs: [], setup });
  for (const version of [1, 0, 1.5, "1", null]) {
    assert.deepEqual(projectConfig({ setup: { ...setup, version } }), { tabs: [], setup });
  }
  for (const value of [null, [], "setup.sh", {}, { version: 1 },
    { script: "" }, { script: "  " }, { script: 42 }, { script: "bad\0path" }]) {
    assert.throws(() => projectConfig({ setup: value }), /"setup"/);
  }
  const exec = async () => ({ code: 0, stdout: "/repo/.bare\n" });
  for (const local of [true, false]) {
    const config = await loadProjectConfig("/repo/main", exec,
      async (path) => path === (local ? "/repo/herdr-project.json" : defaults) ? JSON.stringify({ setup }) : null, defaults);
    assert.deepEqual(config.setup, { ...setup, directory: local ? "/repo" : "/config/herdr-app" });
  }
  await assert.rejects(loadProjectConfig("/repo/main", exec,
    async () => '{"tabs":["nvim"],"setup":{"script":""}}', defaults),
  /\/repo\/herdr-project\.json:.*"setup"/);
});

test("dev commands preserve argument boundaries and require an executable", () => {
  const dev = ["npm", "run", "dev", "--", "argument with spaces", "$(touch should-not-run)", ""];
  assert.deepEqual(projectConfig({ tabs: ["dev"], dev }), { tabs: ["dev"], dev });
  assert.deepEqual(projectConfig({}), { tabs: [] });
  for (const value of [null, "npm run dev", [], [""], [42], ["npm", null], ["npm", "bad\0arg"]]) {
    assert.throws(() => projectConfig({ dev: value }), /"dev"/);
  }
  assert.deepEqual(commandFor("dev", { id: "one" }, "/app", "/home/test", dev),
    ["env", "HERDR_APP_HOME=/app", "HERDR_APP_SPACE_ID=one", "herdr-app-tab", "--start", "dev",
      "env", "-u", "HERDR_ENV", "--", ...dev]);
  assert.deepEqual(commandFor("dev", { id: "one" }, "/app", "/home/test"),
    ["env", "HERDR_APP_HOME=/app", "HERDR_APP_SPACE_ID=one", "herdr-app-tab", "--start", "dev",
      "env", "-u", "HERDR_ENV", "--", "zsh", "-ic", "if [[ -f Makefile ]]; then exec make dev; fi"]);
});

test("dev follows whole-file fallback precedence and invalid commands identify the file", async () => {
  const exec = async () => ({ code: 0, stdout: "/repo/.bare\n" });
  const global = '{"tabs":["nvim"],"dev":["npm","run","dev"]}';
  assert.deepEqual(await loadProjectConfig("/repo/main", exec,
    async (path) => path === defaults ? global : null, defaults),
  { tabs: ["nvim"], dev: ["npm", "run", "dev"] });
  assert.deepEqual(await loadProjectConfig("/repo/main", exec,
    async (path) => path === defaults ? global : '{"tabs":["dev"]}', defaults), { tabs: ["dev"] });
  await assert.rejects(loadProjectConfig("/repo/main", exec,
    async () => '{"dev":"npm run dev"}', defaults), /\/repo\/herdr-project\.json:.*"dev"/);
});

test("tabs normalize aliases and validate the whole declaration", () => {
  assert.deepEqual(projectTabs({ tabs: ["shell-2", "oc-12", "opencode", "nvim"] }),
    ["shell-2", "oc-12", "oc-1", "nvim"]);
  assert.deepEqual(projectTabs({}), []);
  assert.deepEqual(projectTabs({ tabs: [] }), []);
  for (const config of [
    null, [], "shell", { tabs: "nvim" }, { tabs: null }, { tabs: [{}] },
    { tabs: ["oc-0"] }, { tabs: ["oc-01"] }, { tabs: ["oc-9007199254740992"] },
    { tabs: ["nvim", "typo"] }, { tabs: ["oc-1", "opencode"] },
  ]) assert.throws(() => projectTabs(config));
});

test("loads the definition beside .bare from a worktree with spaces in its path", async () => {
  const calls = [];
  const exec = async (...args) => {
    calls.push(args);
    return { code: 0, stdout: "/projects/project one/.bare\n" };
  };
  const read = async (path) => {
    assert.equal(path, "/projects/project one/herdr-project.json");
    return '{"tabs":["oc-2","nvim"],"setup":{"script":"setup.sh"}}';
  };
  assert.deepEqual(await loadProjectTabs("/projects/project one/feature/subdir", exec, read, defaults), ["oc-2", "nvim"]);
  assert.deepEqual(calls, [["git", ["rev-parse", "--path-format=absolute", "--git-common-dir"],
    { cwd: "/projects/project one/feature/subdir", on: null }]]);
});

test("remote definitions and fallback are read on the requested machine", async () => {
  const calls = [];
  const exec = async (...args) => {
    calls.push(args);
    return { code: 0, stdout: "/repo/.bare\n" };
  };
  const reads = [];
  const read = async (path, options) => {
    reads.push([path, options]);
    return path === defaults ? '{"tabs":["dev"],"dev":["remote-dev"]}' : null;
  };
  assert.deepEqual(await loadProjectConfig("/repo/main", exec, read, defaults, "vps"),
    { tabs: ["dev"], dev: ["remote-dev"] });
  assert.equal(calls[0][2].on, "vps");
  assert.deepEqual(reads, [["/repo/herdr-project.json", { on: "vps" }], [defaults, { on: "vps" }]]);
});

test("missing project definitions, regular repositories, and non-Git folders use the configurable fallback", async () => {
  for (const [folder, common, expectedReads] of [
    ["/repo/main", { code: 0, stdout: "/repo/.bare\n" }, ["/repo/herdr-project.json", defaults]],
    ["/regular", { code: 0, stdout: "/regular/.git\n" }, [defaults]],
    ["/plain", { code: 128 }, [defaults]],
    ["", null, [defaults]],
  ]) {
    const reads = [];
    const read = async (path) => {
      reads.push(path);
      return path === defaults ? '{"tabs":["shell-2","oc-2"]}' : null;
    };
    assert.deepEqual(await loadProjectTabs(folder, async () => {
      assert.ok(folder, "No Git lookup without a folder");
      return common;
    }, read, defaults), ["shell-2", "oc-2"]);
    assert.deepEqual(reads, expectedReads);
  }
});

test("a project file replaces the fallback, including an empty or omitted tabs list", async () => {
  for (const config of [{ tabs: ["shell"] }, { tabs: [] }, {}]) {
    const roles = await loadProjectTabs("/repo/main", async () => ({ code: 0, stdout: "/repo/.bare\n" }),
      async (path) => {
        assert.equal(path, "/repo/herdr-project.json", "Do not read defaults when a project definition exists");
        return JSON.stringify(config);
      }, defaults);
    assert.deepEqual(roles, config.tabs ?? []);
  }
});

test("missing fallback leaves a shell, and invalid fallback identifies its path", async () => {
  const exec = async () => ({ code: 128 });
  assert.deepEqual(await loadProjectTabs("/plain", exec, async () => null, defaults), []);
  await assert.rejects(loadProjectTabs("/plain", exec, async () => '{"tabs":["oops"]}', defaults),
    /\/config\/herdr-app\/herdr-project\.json:.*oops/);
});

test("malformed JSON and invalid roles identify the definition file", async () => {
  for (const source of ["{", '{"tabs":["shell","oops"]}']) {
    await assert.rejects(loadProjectTabs("/repo/main", async () => ({ code: 0, stdout: "/repo/.bare\n" }),
      async (path) => {
        assert.equal(path, "/repo/herdr-project.json", "Invalid project definitions must not silently fall back");
        return source;
      }, defaults), /\/repo\/herdr-project\.json:/);
  }
});

test("all named roles use the original fixed order with numeric OpenCode slots", () => {
  const tabs = ["scratch", "shell-3", "oc-10", "opencode", "oc-2", "docker", "git", "rest", "sql", "dev",
    "shell-2", "shell", "nvim"].map((name) => ({ name, named: name !== "scratch" }));
  assert.deepEqual(tabs.sort(compareTabs).map((tab) => tab.name),
    ["nvim", "shell", "shell-2", "dev", "sql", "rest", "git", "docker", "opencode", "oc-2", "oc-10", "shell-3", "scratch"]);
});
