import assert from "node:assert/strict"
import { test } from "node:test"
import { setTimeout as sleep } from "node:timers/promises"
import { adopt, prepare, recovery, reportSession, trackSession } from "../../../dot_config/opencode/extensions/herdr-subject/app-session.js"

function fixture() {
  let version = 0
  let slots = {}
  let conflict = false
  const terminals = Object.fromEntries(["t1", "t2", "t3"].map((id, i) => [id, {
    state: "live", pid: i + 100, labels: { "herdr.space": i === 2 ? "other" : "space", "herdr.tab": `tab${i + 1}` },
  }]))
  const spaces = [
    { id: "space", tabs: [{ id: "tab1", name: "oc-1" }, { id: "tab2", name: "oc-2" }] },
    { id: "other", tabs: [{ id: "tab3", name: "oc-1" }] },
  ]
  const rpc = async (method, params) => {
    if (method === "terminal.get") return terminals[params.terminal]
    if (method === "terminal.label") return Object.assign(terminals[params.terminal].labels, params.labels)
    if (method === "doc.get") return structuredClone({
      version, value: params.name === "herdr-app" ? { spaces } : { slots },
    })
    assert.equal(method, "doc.set")
    if (conflict) {
      conflict = false
      slots["concurrent/oc-1"] = { sessionID: "elsewhere" }
      version++
    }
    if (params.version !== version) throw Object.assign(new Error("Stale document"), { kind: "conflict" })
    slots = params.value.slots
    return { version: ++version }
  }
  return { rpc, terminals, spaces, slots: () => slots, conflict: () => { conflict = true } }
}

test("sessions stay with their space and slot, including after tab recreation", async () => {
  const f = fixture()
  for (const [terminal, space, role, session] of [
    ["t1", "space", "oc-1", "session-a"], ["t2", "space", "oc-2", "session-b"], ["t3", "other", "oc-1", "session-c"],
  ]) {
    assert.equal(await prepare(terminal, space, role, "/project", f.rpc), null)
    await reportSession(terminal, session, f.rpc)
  }
  assert.equal(await prepare("t2", "space", "oc-2", "/project", f.rpc), "session-b")
  assert.equal(await prepare("t1", "space", "oc-1", "/project", f.rpc), "session-a")
  assert.equal(await prepare("t3", "other", "oc-1", "/other", f.rpc), "session-c")
  await reportSession("t1", "session-new", f.rpc)
  assert.equal(f.slots()["space/oc-1"].sessionID, "session-new")
  assert.equal(f.slots()["space/oc-2"].sessionID, "session-b")
})

test("concurrent document updates are merged after a version conflict", async () => {
  const f = fixture()
  await prepare("t1", "space", "oc-1", "/project", f.rpc)
  f.conflict()
  await reportSession("t1", "session-a", f.rpc)
  assert.equal(f.slots()["concurrent/oc-1"].sessionID, "elsewhere")
  assert.equal(f.slots()["space/oc-1"].sessionID, "session-a")
})

test("unmanaged, renamed, superseded, and recovered terminals cannot overwrite a slot", async () => {
  const f = fixture()
  await prepare("t1", "space", "oc-1", "/project", f.rpc)
  await reportSession("t1", "original", f.rpc)
  await reportSession("t2", "unmanaged", f.rpc)
  f.spaces[0].tabs[0].name = "scratch"
  await reportSession("t1", "renamed", f.rpc)
  f.spaces[0].tabs[0].name = "oc-1"
  f.terminals.t1.pid++
  await reportSession("t1", "recovered", f.rpc)
  assert.equal(f.slots()["space/oc-1"].sessionID, "original")
  f.terminals.t1.pid--
  f.terminals.t2.labels["herdr.tab"] = "tab1"
  await prepare("t2", "space", "oc-1", "/project", f.rpc)
  await reportSession("t1", "superseded", f.rpc)
  assert.equal(f.slots()["space/oc-1"].sessionID, "original")
})

test("empty or malformed reports retain the last session and mismatched spaces are rejected", async () => {
  const f = fixture()
  await prepare("t1", "space", "oc-1", "/project", f.rpc)
  await reportSession("t1", "original", f.rpc)
  for (const id of [null, "", "x\nbad", "x".repeat(257)]) await reportSession("t1", id, f.rpc)
  assert.equal(f.slots()["space/oc-1"].sessionID, "original")
  await assert.rejects(prepare("t1", "other", "oc-1", "/project", f.rpc), /space/)
})

test("only a replacement root shell in the original named tab is eligible for recovery", async () => {
  const f = fixture()
  await prepare("t1", "space", "oc-1", "/project with spaces", f.rpc)
  assert.equal(await recovery("t1", "100", f.rpc), undefined)
  f.terminals.t1.pid = 900
  assert.equal(await recovery("t1", "901", f.rpc), undefined, "A nested shell cannot recover")
  assert.deepEqual(await recovery("t1", "900", f.rpc), {
    space: "space", role: "oc-1", folder: "/project with spaces",
  })
  f.spaces[0].tabs[0].name = "scratch"
  assert.equal(await recovery("t1", "900", f.rpc), undefined)
  f.spaces[0].tabs[0].name = "oc-1"
  f.terminals.t1.state = "finished"
  assert.equal(await recovery("t1", "900", f.rpc), undefined)
})

test("already-open named tabs can register after a plugin reload; unmanaged tabs stay out", async () => {
  const f = fixture()
  f.terminals.t1.cwd = "/old project"
  assert.equal(await adopt("t1", f.rpc), true)
  await reportSession("t1", "existing-session", f.rpc)
  assert.equal(f.slots()["space/oc-1"].sessionID, "existing-session")
  assert.equal(f.terminals.t1.labels["pbogut.oc.folder"], "/old project")
  f.spaces[0].tabs[1].name = "scratch"
  assert.equal(await adopt("t2", f.rpc), false)
  assert.equal(f.slots()["space/oc-2"], undefined)
  f.terminals.t2.labels["herdr.tab"] = "tab1"
  assert.equal(await adopt("t2", f.rpc), false, "Another pane cannot take a live slot")
  assert.equal(f.slots()["space/oc-1"].terminal, "t1")
})

test("the reporter follows hydrated root sessions, retries errors, and retains home/exit state", async (t) => {
  const f = fixture()
  await prepare("t1", "space", "oc-1", "/project", f.rpc)
  const sessions = new Map([["root-a", {}], ["child-a", { parentID: "root-a" }], ["root-b", {}]])
  let selected = "child-a"
  let failures = 1
  const dispose = trackSession({
    ui: { router: { current: () => selected ? { type: "session", sessionID: selected } : { type: "home" } } },
    data: { session: {
      get: (id) => sessions.get(id),
      root: (id) => sessions.get(id)?.parentID ?? id,
    } },
  }, "t1", async (...args) => {
    if (failures-- > 0) throw new Error("Temporarily disconnected")
    return f.rpc(...args)
  })
  t.after(dispose)
  async function waitFor(id) {
    for (let i = 0; i < 200; i++) {
      if (f.slots()["space/oc-1"].sessionID === id) return
      await sleep(10)
    }
    assert.fail(`Session ${id} was not reported`)
  }
  await waitFor("root-a")
  selected = "unloaded"
  await sleep(300)
  assert.equal(f.slots()["space/oc-1"].sessionID, "root-a")
  sessions.set("unloaded", {})
  await waitFor("unloaded")
  selected = "root-b"
  await waitFor("root-b")
  selected = null
  await sleep(300)
  assert.equal(f.slots()["space/oc-1"].sessionID, "root-b")
  await dispose()
  selected = "root-a"
  await sleep(300)
  assert.equal(f.slots()["space/oc-1"].sessionID, "root-b")
})

test("an obsolete in-flight report does not replace a newer route", async () => {
  const f = fixture()
  await prepare("t1", "space", "oc-1", "/project", f.rpc)
  await reportSession("t1", "original", f.rpc)
  assert.equal(await reportSession("t1", "obsolete", f.rpc, () => false), undefined)
  assert.equal(f.slots()["space/oc-1"].sessionID, "original")
})
