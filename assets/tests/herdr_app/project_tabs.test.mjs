import assert from "node:assert/strict";
import { test } from "node:test";
import { loadProjectTabs, projectOrder, projectTabs } from "../../../dot_config/herdr-app/mods/pbogut-tabs/project.js";

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
    return '{"tabs":["oc-2","nvim"],"setup":{"version":1,"script":"setup.sh"}}';
  };
  assert.deepEqual(await loadProjectTabs("/projects/project one/feature/subdir", exec, read), ["oc-2", "nvim"]);
  assert.deepEqual(calls, [["git", ["rev-parse", "--path-format=absolute", "--git-common-dir"],
    { cwd: "/projects/project one/feature/subdir" }]]);
});

test("projects without a shared definition use the default shell", async () => {
  const unread = () => assert.fail("No config should be read");
  assert.deepEqual(await loadProjectTabs("", unread, unread), []);
  assert.deepEqual(await loadProjectTabs("/plain", async () => ({ code: 128 }), unread), []);
  assert.deepEqual(await loadProjectTabs("/regular", async () => ({ code: 0, stdout: "/regular/.git\n" }), unread), []);
  assert.deepEqual(await loadProjectTabs("/repo/main",
    async () => ({ code: 0, stdout: "/repo/.bare\n" }), async () => null), []);
});

test("malformed JSON and invalid roles identify the definition file", async () => {
  for (const source of ["{", '{"tabs":["shell","oops"]}']) {
    await assert.rejects(loadProjectTabs("/repo/main", async () => ({ code: 0, stdout: "/repo/.bare\n" }),
      async () => source), /\/repo\/herdr-project\.json:/);
  }
});

test("configured order precedes other named and unnamed tabs", () => {
  const tabs = ["nvim", "oc-1", "shell", "oc-10", "scratch"].map((name) => ({ name, named: name !== "scratch" }));
  assert.deepEqual(tabs.sort((a, b) => projectOrder(a, b, ["oc-10", "shell", "nvim"])).map((tab) => tab.name),
    ["oc-10", "shell", "nvim", "oc-1", "scratch"]);
});
