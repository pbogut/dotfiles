import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtemp, rm } from "node:fs/promises";
import net from "node:net";
import { homedir, tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { afterEach, test } from "node:test";

// Read chezmoi's pinned external source, never the installed plugin.
const source = execFileSync("chezmoi", [
  "--source", fileURLToPath(new URL("../../../", import.meta.url)),
  "cat", join(homedir(), ".config/opencode/herdr-tui-session.js"),
], { encoding: "utf8" });
const { default: plugin } = await import(
  `data:text/javascript;base64,${Buffer.from(source).toString("base64")}`
);
const originalEnv = Object.fromEntries(
  ["HERDR_ENV", "HERDR_PANE_ID", "HERDR_SOCKET_PATH"].map((key) => [key, process.env[key]])
);
const cleanups = [];

afterEach(async () => {
  while (cleanups.length) await cleanups.pop()();
  for (const [key, value] of Object.entries(originalEnv)) {
    if (value === undefined) delete process.env[key];
    else process.env[key] = value;
  }
});

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
async function waitFor(predicate) {
  const deadline = Date.now() + 3_000;
  while (!predicate()) {
    if (Date.now() >= deadline) assert.fail("Timed out waiting for a Herdr report");
    await sleep(10);
  }
}

async function fixture({ status = "idle", permission, form } = {}) {
  const directory = await mkdtemp(join(tmpdir(), "herdr-oc-"));
  const socketPath = join(directory, "herdr.sock");
  const requests = [];
  const sockets = new Set();
  const server = net.createServer((client) => {
    sockets.add(client);
    client.on("close", () => sockets.delete(client));
    let input = "";
    client.on("data", (chunk) => {
      input += chunk;
      if (!input.includes("\n")) return;
      requests.push(JSON.parse(input.slice(0, input.indexOf("\n"))));
      client.end('{"result":{}}\n');
    });
  });
  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(socketPath, resolve);
  });
  cleanups.push(async () => {
    for (const socket of sockets) socket.destroy();
    await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
    await rm(directory, { recursive: true, force: true });
  });
  Object.assign(process.env, {
    HERDR_ENV: "1", HERDR_PANE_ID: "w1:p1", HERDR_SOCKET_PATH: socketPath,
  });

  let route = { type: "session", sessionID: "root-a" };
  let listener;
  const sessions = new Map([
    ["root-a", { id: "root-a" }],
    ["child-a", { id: "child-a", parentID: "root-a" }],
    ["root-b", { id: "root-b" }],
  ]);
  const statuses = new Map([["root-a", status]]);
  const permissions = new Map(permission ? [["child-a", [{ id: permission }]]] : []);
  const forms = new Map(form ? [["child-a", [{ id: form }]]] : []);
  const api = {
    ui: { router: { current: () => route } },
    data: {
      session: {
        get: (id) => sessions.get(id),
        family: (id) => [...sessions.values()].filter((session) => session.parentID === id).map((session) => session.id),
        status: (id) => statuses.get(id) ?? "idle",
        permission: { list: (id) => permissions.get(id) ?? [] },
        form: { list: (id) => forms.get(id) ?? [] },
      },
      listen: (callback) => { listener = callback; return () => { listener = undefined; }; },
    },
  };
  const dispose = plugin.setup(api);
  cleanups.push(dispose);
  return {
    requests, sessions, statuses, permissions, forms,
    emit: (type, data) => listener?.({ details: { type, data } }),
    select: (sessionID) => { route = { type: "session", sessionID }; },
    dispose,
    states: () => requests.filter((request) => request.method === "pane.report_agent"),
    selections: () => requests.filter((request) => request.method === "pane.report_agent_session"),
  };
}

async function expectState(app, state, after = 0) {
  await waitFor(() => app.states().length > after && app.states().at(-1).params.state === state);
}

test("v2 reports the selected root and hydrates already-running and blocked sessions", async () => {
  const app = await fixture({ status: "running", permission: "existing-permission" });
  await expectState(app, "blocked");
  assert.deepEqual(app.selections()[0].params, {
    pane_id: "w1:p1", source: "herdr:opencode", agent: "opencode",
    agent_session_id: "root-a", session_start_source: "select",
  });
  const before = app.states().length;
  app.permissions.clear();
  await expectState(app, "working", before);
  app.select("child-a");
  await sleep(150);
  assert.ok(app.requests.every(({ params }) => params.agent_session_id === "root-a"));
});

test("v2 lifecycle and child permission/form events report state under the resumable root ID", async () => {
  const app = await fixture();
  await expectState(app, "idle");
  const emit = async (type, data, state) => {
    const before = app.states().length;
    app.emit(type, data);
    await expectState(app, state, before);
  };
  await emit("session.execution.started", { sessionID: "root-a" }, "working");
  await emit("permission.asked", { sessionID: "child-a", id: "permission-1" }, "blocked");
  await emit("form.created", { form: { sessionID: "child-a", id: "form-1" } }, "blocked");
  await emit("permission.replied", { sessionID: "child-a", requestID: "permission-1" }, "blocked");
  await emit("form.replied", { sessionID: "child-a", id: "form-1" }, "working");
  await emit("session.execution.succeeded", { sessionID: "root-a" }, "idle");
  await emit("session.execution.failed", { sessionID: "root-a" }, "blocked");
  await emit("session.execution.started", { sessionID: "root-a" }, "working");
  await emit("session.execution.interrupted", { sessionID: "root-a" }, "idle");
  let seq = 0;
  for (const { params } of app.states()) {
    assert.equal(params.agent_session_id, "root-a");
    assert.equal(params.source, "herdr:opencode");
    assert.equal(params.agent, "opencode");
    assert.equal(params.pane_id, "w1:p1");
    assert.ok(params.seq > seq);
    seq = params.seq;
  }
});

test("other shared-server sessions cannot change this pane; selecting one updates its resume ID", async () => {
  const app = await fixture();
  await expectState(app, "idle");
  app.emit("session.execution.started", { sessionID: "root-b" });
  app.emit("permission.asked", { sessionID: "root-b", id: "other-permission" });
  await sleep(150);
  assert.ok(app.states().every(({ params }) => params.state === "idle" && params.agent_session_id === "root-a"));
  const before = app.states().length;
  app.statuses.set("root-b", "running");
  app.select("root-b");
  await expectState(app, "working", before);
  assert.equal(app.selections().at(-1).params.agent_session_id, "root-b");
  assert.equal(app.states().at(-1).params.agent_session_id, "root-b");
});

test("a reply received before cache hydration cannot resurrect a blocker", async () => {
  const app = await fixture({ status: "running" });
  await expectState(app, "working");
  app.emit("permission.asked", { sessionID: "child-a", id: "late-permission" });
  await expectState(app, "blocked");
  app.permissions.set("child-a", [{ id: "late-permission" }]);
  const before = app.states().length;
  app.emit("permission.replied", { sessionID: "child-a", requestID: "late-permission" });
  await expectState(app, "working", before);
  await sleep(150);
  assert.equal(app.states().at(-1).params.state, "working");
});

test("rapid A-to-B-to-A selection discards stale queued reports, and disposal stops reporting", async () => {
  const app = await fixture();
  await expectState(app, "idle");
  const before = app.requests.length;
  app.select("root-b");
  app.emit("session.execution.started", { sessionID: "root-b" });
  app.select("root-a");
  app.emit("session.execution.started", { sessionID: "root-a" });
  await expectState(app, "working");
  assert.ok(app.requests.slice(before).every(({ params }) => params.agent_session_id === "root-a"));
  app.dispose();
  await sleep(30);
  const stopped = app.requests.length;
  app.select("root-b");
  app.emit("session.execution.failed", { sessionID: "root-b" });
  await sleep(150);
  assert.equal(app.requests.length, stopped);
});

test("v2 reporting is inactive outside a Herdr pane", () => {
  delete process.env.HERDR_ENV;
  assert.equal(plugin.setup({}), undefined);
  process.env.HERDR_ENV = "1";
  delete process.env.HERDR_PANE_ID;
  assert.equal(plugin.setup({}), undefined);
});
