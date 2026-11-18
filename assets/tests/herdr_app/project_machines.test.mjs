import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";
import vm from "node:vm";
import { machinePaths, pickerMachines } from "../../../dot_config/herdr-app/mods/pbogut-projects/machines.js";
import { machinePaths as tabPaths } from "../../../dot_config/herdr-app/mods/pbogut-tabs/project.js";

const root = new URL("../../../dot_config/herdr-app/mods/pbogut-projects/", import.meta.url);
const ok = (stdout) => ({ code: 0, stdout, stderr: "" });
const settle = () => new Promise(setImmediate);
const plain = (value) => JSON.parse(JSON.stringify(value));

async function fixture(active = null) {
  const calls = [], reads = [], commands = [], requests = [];
  const context = vm.createContext({});
  const spaces = [
    { id: "local", folder: "/local/repo", machine: null, active: !active },
    { id: "vps/one", folder: "/remote/repo", machine: "vps", active: active === "vps" },
  ];
  const machines = [{ name: null, layout: "ready" }, { name: "vps", layout: "ready" }];
  const marked = { local: true, "vps/one": true };
  const input = () => ({ on() {}, focus() {}, value: () => "", set_value() {} });
  const mock = (values) => new vm.SyntheticModule(Object.keys(values), function () {
    for (const [key, value] of Object.entries(values)) this.setExport(key, value);
  }, { context });
  const modules = {
    "gpui-kit": mock({ View: class {}, div: () => {} }),
    "gpui-base": mock({ v_flex() {}, h_flex() {}, InputState: { new: input }, Input: {},
      v_virtual_list() {}, VirtualListScrollHandle: { new: () => ({ scroll_to_item() {} }) }, Scrollbar: {} }),
    herdr: mock({
      appHome: () => "/local/app", home: () => "/local/home", checking: () => false,
      spaces: () => spaces, machines: () => machines, props: () => ({ overlay: "picker" }),
      closeOverlay() {}, run: (...args) => commands.push(plain(args)), theme() {}, settings() {},
      shared: key => key === "pbogut.projects.spaces" ? marked : null,
      exec: async (name, args, options) => {
        calls.push(plain([name, args, options]));
        if (name === "sh") return ok("/remote/home\n/remote/app\n");
        return new Promise((resolve, reject) => requests.push({ resolve, reject, on: options.on }));
      },
      readTextFile: async (path, options) => {
        reads.push(plain([path, options]));
        return JSON.stringify({ root: options.on ? "/remote" : "/local", aliases: {} });
      },
    }),
  };
  for (const file of ["projects.js", "machines.js", "worktrees.js"]) {
    modules[`./${file}`] = new vm.SourceTextModule(await readFile(new URL(file, root), "utf8"), { context });
  }
  const main = new vm.SourceTextModule(await readFile(new URL("main.js", root), "utf8"), { context });
  await main.link((name) => modules[name]);
  await main.evaluate();
  const cx = { spawn: (fn) => fn(cx), notify() {}, focus_handle() {}, bind_keys() {} };
  const view = new main.namespace.default();
  view.init({}, cx);
  await settle();
  return { view, cx, calls, reads, commands, requests, spaces, machines, marked,
    async cycle(backwards = false) { view.cycleMachine(backwards, cx); await settle(); } };
}

test("machine choices keep local first and the current machine visible if disconnected", () => {
  assert.deepEqual(pickerMachines([
    { name: null, layout: "ready" }, { name: "vps", layout: "ready" },
    { name: "offline", layout: "unavailable" }, { name: "loading", layout: "loading" },
  ], "offline"), [null, "vps", "offline"]);
});

test("remote paths come from that host and failures never fall back to local paths", async () => {
  for (const resolvePaths of [machinePaths, tabPaths]) {
    const local = { home: "/local/home", appHome: "/local/app" };
    assert.equal(await resolvePaths(null, () => assert.fail(), local), local);
    assert.deepEqual(await resolvePaths("vps", async (_name, _args, options) => {
      assert.deepEqual(options, { on: "vps" });
      return ok("/different home\n/custom app\n");
    }, local), { home: "/different home", appHome: "/custom app" });
    await assert.rejects(resolvePaths("vps", async () => { throw new Error("unreachable"); }, local), /unreachable/);
    await assert.rejects(resolvePaths("vps", async () => ok("\n"), local), /Invalid home paths/);
  }
});

test("the active remote machine supplies discovery settings, helper paths and project requests", async () => {
  const app = await fixture("vps");
  assert.equal(app.view.machine, "vps");
  assert.deepEqual(app.reads, [["/remote/app/mods/pbogut-projects/projects.json", { on: "vps" }]]);
  assert.deepEqual(app.calls.at(-1), ["env", ["PROJECTS=/remote", "/remote/home/.scripts/ls-project", "-f"], { on: "vps" }]);
  app.requests[0].resolve(ok("/remote/new\n"));
  await settle();
  assert.deepEqual(plain(app.view.rows()).map((row) => row.folder), ["/remote/repo", "/remote/new"]);
  app.view.open(app.view.rows()[1]);
  const project = JSON.parse(decodeURIComponent(app.commands[0][0].split("@")[1]));
  assert.equal(project.machine, "vps");
  assert.equal(project.folder, "/remote/new");
});

test("cycling preserves search, resets selection and ignores late results even after cycling back", async () => {
  const app = await fixture();
  app.view.query = "repo";
  app.view.at = 7;
  await app.cycle();
  assert.equal(app.view.machine, "vps");
  assert.equal(app.view.query, "repo");
  assert.equal(app.view.at, 0);
  assert.equal(app.view.rows().length, 1);
  await app.cycle(true);
  assert.equal(app.view.machine, null);
  app.requests[2].resolve(ok("/local/repo-new\n"));
  await settle();
  app.requests[0].resolve(ok("/local/stale\n"));
  app.requests[1].reject(new Error("old remote failure"));
  await settle();
  assert.deepEqual(plain(app.view.projects), ["/local/repo-new"]);
  assert.equal(app.view.error, null);
  assert.equal(app.view.loading, false);
});

test("a failed remote lookup clears local results and keeps its machine and error", async () => {
  const app = await fixture();
  app.requests[0].resolve(ok("/local/new\n"));
  await settle();
  await app.cycle();
  assert.deepEqual(plain(app.view.projects), []);
  app.requests[1].reject(new Error("remote unavailable"));
  await settle();
  assert.equal(app.view.machine, "vps");
  assert.match(app.view.error, /remote unavailable/);
  assert.equal(app.view.loading, false);
  assert.ok(app.view.rows().every((row) => row.machine === "vps"));
});

test("the picker reads project markers for both its rows and its open action", async () => {
  const app = await fixture("vps");
  delete app.marked["vps/one"];
  app.requests[0].resolve(ok("/remote/repo\n"));
  await settle();
  const rows = plain(app.view.rows());
  assert.equal(rows.length, 1);
  assert.equal(rows[0].id, undefined);
  app.view.open(rows[0]);
  const project = JSON.parse(decodeURIComponent(app.commands[0][0].split("@")[1]));
  assert.equal(project.folder, "/remote/repo");
  assert.equal(project.machine, "vps");
  assert.equal(project.id, undefined);
});
