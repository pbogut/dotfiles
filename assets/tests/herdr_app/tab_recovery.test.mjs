import assert from "node:assert/strict";
import { test } from "node:test";
import { prepare, recovery } from "../../../dot_config/herdr-app/mods/pbogut-tabs/recovery.mjs";

function fixture() {
  const terminal = { state: "live", pid: 100, labels: { "herdr.space": "space", "herdr.tab": "tab" } };
  const tab = { id: "tab", name: "git" };
  const rpc = async (method, params) => {
    if (method === "terminal.get") return terminal;
    if (method === "terminal.label") return Object.assign(terminal.labels, params.labels);
    assert.equal(method, "doc.get");
    assert.equal(params.name, "herdr-app");
    return { value: { spaces: [{ id: "space", tabs: [tab] }] } };
  };
  const argv = ["lazygit", "argument with spaces", "", "$(touch do-not-run)", "last\n"];
  const register = () => prepare("t1", "space", "git", "/project's folder", "/app home", argv, rpc);
  return { terminal, tab, rpc, argv, register };
}

test("recovery replays the registered command and directory with exact argument boundaries", async () => {
  const f = fixture();
  await f.register();
  f.terminal.pid = 900;
  f.terminal.cwd = "/somewhere else";
  assert.deepEqual(await recovery("t1", "900", f.rpc), {
    space: "space", tab: "tab", role: "git", folder: "/project's folder",
    appHome: "/app home", argv: f.argv, pid: 100,
  });
  await f.register();
  assert.equal(await recovery("t1", "900", f.rpc), undefined, "The new launcher consumes the old PID marker");
});

test("only the replacement root shell can recover its registered tab", async () => {
  const f = fixture();
  assert.equal(await recovery("t1", "100", f.rpc), undefined, "Unregistered panes stay shells");
  await f.register();
  assert.equal(await recovery("t1", "100", f.rpc), undefined, "The original shell cannot recover");
  f.terminal.pid = 900;
  assert.equal(await recovery("t1", "901", f.rpc), undefined, "Nested shells cannot recover");
  assert.ok(await recovery("t1", "900", f.rpc));
  f.terminal.state = "finished";
  assert.equal(await recovery("t1", "900", f.rpc), undefined, "Normal exit does not recover");
});

test("renaming or moving a registered tab prevents recovery", async () => {
  for (const change of [
    f => { f.tab.name = "scratch"; },
    f => { f.tab.id = "another"; },
    f => { f.terminal.labels["herdr.space"] = "other"; },
    f => { f.terminal.labels["herdr.tab"] = "other"; },
  ]) {
    const f = fixture();
    await f.register();
    f.terminal.pid = 900;
    change(f);
    assert.equal(await recovery("t1", "900", f.rpc), undefined);
  }
});

test("registration requires a supported role, command, and matching live space", async () => {
  const f = fixture();
  for (const [space, role, argv] of [["other", "git", ["lazygit"]], ["space", "shell", ["zsh"]],
    ["space", "git", []], ["space", "git", [""]]]) {
    await assert.rejects(prepare("t1", space, role, "/project", "/app", argv, f.rpc));
  }
  f.terminal.state = "finished";
  await assert.rejects(f.register());
  assert.equal(f.terminal.labels["pbogut.tab.launch"], undefined);
});
