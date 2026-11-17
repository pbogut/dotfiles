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

async function fixture(spaces, exec) {
  const tasks = [];
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
      hc: async () => ({ code: 0, stdout: '{"machines":[]}' }), exec, watchFolder() {},
    }),
  };
  const main = new vm.SourceTextModule(await readFile(source, "utf8"), { context });
  await main.link(name => modules[name]);
  await main.evaluate();
  const cx = { spawn: callback => tasks.push(callback(cx)), notify() {}, timer: { every() {} } };
  const view = new main.namespace.default();
  view.init({}, cx);
  view.watch = () => {}; // Filesystem watches aren't needed to test the rendered letters.
  return {
    state, view,
    refresh: async () => {
      view.checkNew(cx);
      while (tasks.length) await Promise.all(tasks.splice(0));
    },
    row: space => text(view.row({ w: space, i: 0, g: null, tree: null }, {})),
  };
}

test("real Git worktrees use the repository initial, independently of labels and terminal cd", async t => {
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
  await git(project, "worktree", "add", feature, "feature");
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
  });
  await app.refresh();
  for (const [i, letter] of ["P", "P", "P", "W", "W", "N"].entries()) {
    assert.deepEqual(app.row(spaces[i]), [letter, spaces[i].name]);
  }
  // Even a fresh lookup after cd into another repo must retain the configured project.
  app.state.panes = [{ tab: "tab0", terminal: "t0", cwd: normal }];
  app.state.now += 60_001;
  spaces[0].name = "a custom name";
  await app.refresh();
  assert.deepEqual(app.row(spaces[0]), ["P", "a custom name"]);
  spaces[0].folder = normal;
  await app.refresh();
  assert.deepEqual(app.row(spaces[0]), ["W", "a custom name"]);
});

test("lookups distinguish machines, share folder caches and retry temporary failures", async () => {
  const folder = "/projects/gitlab.com/team/pms/branch";
  const spaces = [
    { id: "local", name: "gl/team/pms/branch", folder },
    { id: "duplicate", name: "renamed", folder },
    { id: "remote", name: "gl/team/pms/branch", folder, machine: "work" },
    { id: "no-folder", name: "scratch" },
  ];
  const calls = [];
  let offline = false;
  const app = await fixture(spaces, async (_bin, args, options) => {
    if (!args.includes("--git-common-dir")) return { code: 1, stdout: "", stderr: "not a git repository" };
    calls.push(options);
    if (offline && options.on) throw new Error("offline");
    return { code: 0, stdout: options.on ? "/repos/remote.git\n" : "/repos/pms/.bare\n" };
  });
  // Exercise only the icon lookup to count its requests separately from git status.
  app.view.refreshGit = () => {};
  await app.refresh();
  assert.equal(calls.length, 2);
  assert.deepEqual(spaces.map(s => app.row(s)[0]), ["P", "P", "R", "S"]);
  await app.refresh();
  assert.equal(calls.length, 2, "Do not launch git on every 250ms tick");
  offline = true;
  app.state.now += 60_001;
  await app.refresh();
  assert.equal(app.row(spaces[2])[0], "R", "Retain the remote's last known initial");
  offline = false;
  app.state.now += 60_001;
  await app.refresh();
  assert.equal(calls.length, 6, "Retry after a temporary failure");
  spaces.splice(0, 3);
  await app.refresh();
  assert.equal(app.view.projects.size, 0, "Closed spaces release their cached entries");
});
