import assert from "node:assert/strict";
import { test } from "node:test";
import { loadProjectTabs, projectOrder, projectTabs } from "../../../dot_config/herdr-app/mods/pbogut-tabs/project.js";

const defaults = "/config/herdr-app/herdr-project.json";

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
  assert.deepEqual(await loadProjectTabs("/projects/project one/feature/subdir", exec, read, defaults), ["oc-2", "nvim"]);
  assert.deepEqual(calls, [["git", ["rev-parse", "--path-format=absolute", "--git-common-dir"],
    { cwd: "/projects/project one/feature/subdir" }]]);
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

test("configured order precedes other named and unnamed tabs", () => {
  const tabs = ["nvim", "oc-1", "shell", "oc-10", "scratch"].map((name) => ({ name, named: name !== "scratch" }));
  assert.deepEqual(tabs.sort((a, b) => projectOrder(a, b, ["oc-10", "shell", "nvim"])).map((tab) => tab.name),
    ["oc-10", "shell", "nvim", "oc-1", "scratch"]);
});
