import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { test } from "node:test";
import { promisify } from "node:util";
import vm from "node:vm";

const execute = promisify(execFile);
const env = {
  ...process.env, GIT_CONFIG_GLOBAL: "/dev/null", GIT_CONFIG_NOSYSTEM: "1",
  GIT_AUTHOR_NAME: "Test", GIT_AUTHOR_EMAIL: "test@example.com",
  GIT_COMMITTER_NAME: "Test", GIT_COMMITTER_EMAIL: "test@example.com",
};
const git = (cwd, ...args) => execute("git", ["-c", "core.hooksPath=/dev/null", ...args], { cwd, env });
const source = new URL("../../../dot_config/herdr-app/mods/pbogut-spaces/main.js", import.meta.url);

function element() {
  const nodes = [];
  const el = new Proxy({ nodes }, {
    get: (target, key) => key in target ? target[key]
      : key === "child" ? child => { nodes.push(child); return el; }
      : key === "children" ? children => { nodes.push(...children); return el; }
      : key === "when" ? (condition, callback) => condition ? callback(el) : el
      : () => el,
  });
  return el;
}
const text = el => typeof el === "string" ? [el] : el.nodes.flatMap(text);

async function fixture(spaces, exec, readTextFile = async () => null) {
  const tasks = [], notices = [];
  let receive;
  const state = { now: 100_000, panes: [] };
  const context = vm.createContext({
    Date: { now: () => state.now },
    localStorage: { getItem: () => null, setItem() {} },
  });
  function mock(values) {
    return new vm.SyntheticModule(Object.keys(values), function () {
      for (const [key, value] of Object.entries(values)) this.setExport(key, value);
    }, { context });
  }
  const modules = {
    "gpui-kit": mock({ View: class {}, div: element, svg: element }),
    "gpui-base": mock({ v_flex: element, h_flex: element, ScrollHandle: { new: () => ({ scroll_to_item() {} }) } }),
    herdr: mock({
      spaces: () => spaces, panes: () => state.panes, machines: () => [],
      window: () => ({ active: true }), layout: () => ({}),
      run() {}, openOverlay() {}, theme: () => ({}), shared: () => null, setShared() {},
      hc: async () => ({ code: 0, stdout: '{"machines":[]}' }), exec, readTextFile, watchFolder() {},
      checking: () => false, notify: message => notices.push(message),
      nextCommand: () => new Promise(resolve => { receive = resolve; }),
    }),
  };
  const main = new vm.SourceTextModule(await readFile(source, "utf8"), { context });
  await main.link(name => modules[name]);
  await main.evaluate();
  const cx = { spawn: callback => tasks.push(callback(cx)),
    notify: () => view.refreshProjects(spaces, cx), timer: { every() {} } };
  const view = new main.namespace.default();
  view.init({}, cx);
  tasks.pop(); // The command listener stays alive for the lifetime of the mod.
  view.watch = () => {}; // Filesystem watches aren't needed to test the rendered letters.
  return {
    state, view, notices,
    reload: async (space) => {
      receive(`reload@${encodeURIComponent(JSON.stringify(space))}`);
      await new Promise(setImmediate);
      while (tasks.length) await Promise.all(tasks.splice(0));
    },
    refresh: async () => {
      view.refreshProjects(spaces, cx);
      view.checkNew(cx);
      while (tasks.length) await Promise.all(tasks.splice(0));
    },
    row: (space, g = null) => text(view.row({ w: space, i: 0, g, tree: null }, {})),
  };
}

test("real Git worktrees use the project name and initial, independently of labels and terminal cd", async t => {
  const root = await mkdtemp("/tmp/opencode/herdr-space-initials-");
  t.after(() => rm(root, { recursive: true, force: true }));
  const normal = join(root, "website");
  await mkdir(normal);
  await git(normal, "init", "-b", "main");
  await git(normal, "-c", "commit.gpgsign=false", "commit", "--allow-empty", "-m", "fixture");
  const normalWorktree = join(root, "different-branch-name");
  await git(normal, "worktree", "add", "-b", "feature", normalWorktree);

  const project = join(root, "gitlab.com", "assuredpharmacy", "pms");
  await mkdir(project, { recursive: true });
  await git(root, "clone", "--bare", normal, join(project, ".bare"));
  await writeFile(join(project, ".git"), "gitdir: ./.bare\n");
  const main = join(project, "main");
  const feature = join(project, "2026-11-17-feature");
  await git(project, "worktree", "add", main, "main");
  await git(project, "worktree", "add", "-b", "2026-11-17-feature", feature, "feature");
  const notes = join(root, "notes");
  await mkdir(notes);
  const spaces = [main, feature, project, normal, normalWorktree, notes].map((folder, i) => ({
    id: `s${i}`, name: `gl/ap/${i < 3 ? "pms" : "other"}/${i}`,
    folder, machine: null, tabs: [{ id: `tab${i}` }],
  }));
  const app = await fixture(spaces, async (bin, args, { cwd, on }) => {
    assert.equal(bin, "git");
    assert.equal(on, null);
    try {
      return { code: 0, ...await git(cwd, ...args) };
    } catch (error) {
      return { code: error.code, stdout: error.stdout, stderr: error.stderr };
    }
  }, path => readFile(path, "utf8").catch(error => {
    if (error.code === "ENOENT") return null;
    throw error;
  }));
  await app.refresh();
  for (const [i, name] of ["pms", "pms", "pms", "website", "website", "notes"].entries()) {
    assert.deepEqual(app.row(spaces[i]), [name[0].toUpperCase(), name]);
  }
  const branchInfo = app.view.git[JSON.stringify([null, feature])];
  assert.deepEqual(app.row(spaces[1], branchInfo), ["P", "pms", "feature"]);
  assert.equal(branchInfo.branch, "2026-11-17-feature");
  // Even a fresh lookup after cd into another repo must retain the configured project.
  app.state.panes = [{ tab: "tab0", terminal: "t0", cwd: normal }];
  app.state.now += 60_001;
  spaces[0].name = "a custom name";
  await app.refresh();
  assert.deepEqual(app.row(spaces[0]), ["P", "pms"]);
  assert.equal(spaces[0].name, "a custom name");
  await writeFile(join(project, "herdr-project.json"), '{"name":" Dispensary ","tabs":["nvim"]}');
  await writeFile(join(feature, "herdr-project.json"), '{"name":"Wrong worktree override"}');
  app.state.now += 60_001;
  await app.refresh();
  assert.deepEqual(app.row(spaces[1]), ["P", "pms"], "Saving a config does not refresh its label");
  await app.reload(spaces[1]);
  for (const space of spaces.slice(0, 3)) assert.deepEqual(app.row(space), ["D", "Dispensary"]);
  assert.deepEqual(app.row(spaces[1], branchInfo), ["D", "Dispensary", "feature"]);
  assert.equal((await git(feature, "symbolic-ref", "--short", "HEAD")).stdout.trim(), "2026-11-17-feature");
  spaces[0].folder = normal;
  await app.refresh();
  assert.deepEqual(app.row(spaces[0]), ["W", "website"]);
  await writeFile(join(normal, "herdr-project.json"), '{"name":"Site"}');
  await writeFile(join(notes, "herdr-project.json"), '{"name":"Research"}');
  app.state.now += 60_001;
  await app.refresh();
  await app.reload(spaces[0]);
  await app.reload(spaces[5]);
  for (const i of [0, 3, 4]) assert.deepEqual(app.row(spaces[i]), ["S", "Site"]);
  assert.deepEqual(app.row(spaces[5]), ["R", "Research"]);
});

test("lookups distinguish machines, share folder caches and retry only on explicit reload", async () => {
  const folder = "/projects/gitlab.com/team/pms/branch";
  const spaces = [
    { id: "local", name: "gl/team/pms/branch", folder },
    { id: "duplicate", name: "renamed", folder },
    { id: "remote", name: "gl/team/pms/branch", folder, machine: "work" },
    { id: "no-folder", name: "scratch" },
  ];
  const calls = [];
  const reads = [];
  let offline = false;
  const app = await fixture(spaces, async (_bin, args, options) => {
    if (!args.includes("--git-common-dir")) return { code: 1, stdout: "", stderr: "not a git repository" };
    calls.push(options);
    if (offline && options.on) throw new Error("offline");
    return { code: 0, stdout: options.on ? "/repos/remote.git\n" : "/repos/pms/.bare\n" };
  }, async (path, { on }) => {
    reads.push([path, on]);
    return on ? '{"name":"Remote project"}' : null;
  });
  // Exercise only the icon lookup to count its requests separately from git status.
  app.view.refreshGit = () => {};
  await app.refresh();
  assert.equal(calls.length, 2);
  assert.deepEqual(spaces.map(s => app.row(s)[0]), ["P", "P", "R", "S"]);
  assert.deepEqual(app.row(spaces[2]), ["R", "Remote project"]);
  assert.deepEqual(reads, [["/repos/pms/herdr-project.json", null], ["/repos/remote.git/herdr-project.json", "work"]]);
  await app.refresh();
  assert.equal(calls.length, 2, "Do not launch git on every 250ms tick");
  offline = true;
  app.state.now += 60_001;
  await app.refresh();
  assert.equal(calls.length, 2, "Elapsed time never rereads project config or resolves its root");
  await app.reload(spaces[2]);
  assert.equal(app.row(spaces[2])[0], "R", "Retain the remote's last known initial");
  offline = false;
  app.state.now += 60_001;
  await app.refresh();
  await app.reload(spaces[2]);
  assert.equal(calls.length, 4, "Retry only the requested machine after a temporary failure");
  spaces.splice(0, 3);
  await app.refresh();
  assert.equal(app.view.projects.size, 0, "Closed spaces release their cached entries");
});

test("optional names fall back safely and branch shortening changes display text only", async () => {
  const space = Object.freeze({ id: "pms", name: "gl/ap/pms/2026-11-17-fix-stock", folder: "/repo/main" });
  let definition = '{"name":" Pharmacy "}';
  const app = await fixture([space],
    async () => ({ code: 0, stdout: "/repo/.bare\n" }),
    async path => {
      assert.equal(path, "/repo/herdr-project.json");
      return definition;
    });
  app.view.refreshGit = () => {};
  await app.refresh();
  for (const [raw, shown] of [
    ["2026-11-17-fix-stock", "fix-stock"],
    ["main", "main"], ["master", "master"], ["(detached)", "(detached)"],
    ["feature/2026-11-17-report", "feature/2026-11-17-report"],
    ["2026-11-17-", "2026-11-17-"],
  ]) {
    const info = Object.freeze({ name: ".bare", branch: raw, ahead: 2, behind: 1 });
    assert.deepEqual(app.row(space, info), ["P", "Pharmacy", shown, "↑2", "↓1"]);
  }
  definition = "{";
  await app.reload(space);
  assert.deepEqual(app.row(space), ["P", "Pharmacy"], "A failed reload retains the last valid name");
  assert.match(app.notices.at(-1).body, /\/repo\/herdr-project.json/);
  for (const invalid of [null, "{", "null", "[]", "{}", '{"name":42}', '{"name":""}', '{"name":"  "}']) {
    definition = invalid;
    app.state.now += 60_001;
    await app.refresh();
    await app.reload(space);
    assert.deepEqual(app.row(space), ["R", "repo"]);
  }
  definition = '{"name":"New name"}';
  app.state.now += 60_001;
  await app.refresh();
  await app.reload(space);
  assert.deepEqual(app.row(space), ["N", "New name"]);
  assert.equal(space.name, "gl/ap/pms/2026-11-17-fix-stock");
  assert.equal(space.folder, "/repo/main");
});

test("a reload arriving during initial reads runs afterwards and updates only siblings on the same machine", async () => {
  const spaces = [
    { id: "one", folder: "/repo/main" },
    { id: "two", folder: "/repo/feature" },
    { id: "remote", folder: "/repo/main", machine: "remote" },
  ];
  let release, definition = '{"name":"Before"}';
  const gate = new Promise(resolve => { release = resolve; });
  const reads = [];
  const app = await fixture(spaces, async () => ({ code: 0, stdout: "/repo/.bare\n" }),
    async (_path, { on }) => {
      reads.push(on);
      const snapshot = definition;
      await gate;
      return snapshot;
    });
  app.view.refreshGit = () => {};
  const loading = app.refresh();
  await new Promise(setImmediate);
  definition = '{"name":"After"}';
  const reloading = app.reload(spaces[0]);
  release();
  await Promise.all([loading, reloading]);
  assert.deepEqual(spaces.map(space => app.row(space)[1]), ["After", "After", "Before"]);
  const count = reads.length;
  app.state.now += 600_000;
  await app.refresh();
  assert.equal(reads.length, count, "Time and rendering cause no config reads");
});
