import assert from "node:assert/strict";
import { test } from "node:test";
import { createDatedWorktree } from "../../../dot_config/herdr-app/mods/pbogut-projects/worktrees.js";

const root = "/projects/repo";
const row = { folder: `${root}/older-worktree` };
const folder = `${root}/2026-11-17-new-branch`;
const script = "/home/test/.scripts/git-new-dated-worktree";
const listing = (paths) => paths.map((path) => `worktree ${path}\0HEAD abc\0branch refs/heads/main\0\0`).join("");
const ok = (stdout) => ({ code: 0, stdout, stderr: "" });

function fixture(overrides = {}) {
  const calls = [];
  const replies = [
    overrides.common ?? ok(`${root}/.bare\n`),
    overrides.before ?? ok(listing([`${root}/.bare`, row.folder])),
    overrides.create ?? ok(`Preparing worktree\n${folder}\n`),
    overrides.after ?? ok(listing([`${root}/.bare`, row.folder, folder])),
  ];
  return {
    calls,
    exec: async (...args) => { calls.push(args); return replies.shift(); },
  };
}

test("uses the existing helper from the .bare root and normalizes spaces", async () => {
  const f = fixture();
  assert.equal(await createDatedWorktree(row, "new branch", f.exec, script), folder);
  assert.deepEqual(f.calls[0], ["git", ["rev-parse", "--path-format=absolute", "--git-common-dir"], { cwd: row.folder }]);
  assert.deepEqual(f.calls[2], [script, ["new-branch"], { cwd: root, timeout: 600_000 }]);
});

test("does not run the helper for an empty name, remote space, or ordinary repo", async () => {
  for (const [target, name] of [[row, "   "], [{ ...row, machine: "vps" }, "branch"], [{}, "branch"]]) {
    const f = fixture();
    await assert.rejects(createDatedWorktree(target, name, f.exec, script));
    assert.equal(f.calls.length, 0);
  }
  const f = fixture({ common: ok(`${root}/.git\n`) });
  await assert.rejects(createDatedWorktree(row, "branch", f.exec, script), /\.bare/);
  assert.equal(f.calls.length, 1);
});

test("detects Git failures hidden by the helper's final echo", async () => {
  const f = fixture({
    create: { code: 0, stdout: `${folder}\n`, stderr: "fatal: invalid branch name\n" },
    after: ok(listing([`${root}/.bare`, row.folder])),
  });
  await assert.rejects(createDatedWorktree(row, "bad..name", f.exec, script), /invalid branch name/);
});

test("avoids the helper's whitespace-path parsing bug", async () => {
  const f = fixture({ common: ok("/projects/repo with spaces/.bare\n") });
  await assert.rejects(createDatedWorktree(row, "branch", f.exec, script), /whitespace/);
  assert.equal(f.calls.length, 1);
});

test("does not treat an existing worktree as newly created", async () => {
  const f = fixture({ before: ok(listing([`${root}/.bare`, row.folder, folder])) });
  await assert.rejects(createDatedWorktree(row, "new branch", f.exec, script), /did not create/);
});

test("passes branch text as one argument and reports process failures", async () => {
  const name = "literal;$(touch sentinel)";
  const f = fixture({ create: { code: 1, stdout: "", stderr: "creation failed" } });
  await assert.rejects(createDatedWorktree(row, name, f.exec, script), /creation failed/);
  assert.deepEqual(f.calls[2][1], ["literal;$(touch-sentinel)"]);
});
