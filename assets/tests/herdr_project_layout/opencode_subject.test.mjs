import assert from "node:assert/strict"
import { mkdtemp, rm } from "node:fs/promises"
import net from "node:net"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { setTimeout as sleep } from "node:timers/promises"
import { test } from "node:test"
import plugin from "../../../dot_config/opencode/extensions/herdr-subject/tui.ts"

async function waitFor(predicate) {
  const deadline = Date.now() + 3000
  while (!predicate()) {
    assert.ok(Date.now() < deadline, "Timed out waiting for subject metadata")
    await sleep(10)
  }
}

async function fixture(t, failures = 0) {
  const directory = await mkdtemp(join(tmpdir(), "herdr-subject-"))
  const socketPath = join(directory, "herdr.sock")
  const requests = []
  const sockets = new Set()
  const server = net.createServer((socket) => {
    sockets.add(socket)
    socket.on("close", () => sockets.delete(socket))
    let input = ""
    socket.on("data", (chunk) => {
      input += chunk
      if (!input.includes("\n")) return
      requests.push(JSON.parse(input.slice(0, input.indexOf("\n"))))
      socket.end(failures-- > 0 ? '{"error":{"code":"retry"}}\n' : '{"result":{}}\n')
    })
  })
  await new Promise((resolve) => server.listen(socketPath, resolve))
  const env = { HERDR_ENV: "1", HERDR_PANE_ID: "w1:p1", HERDR_SOCKET_PATH: socketPath }
  const previous = Object.fromEntries(Object.keys(env).map((key) => [key, process.env[key]]))
  Object.assign(process.env, env)
  const sessions = new Map([
    ["root-a", { title: "Fix checkout validation" }],
    ["child-a", { title: "Investigate validation", parentID: "root-a" }],
    ["root-b", { title: "Review shipping changes" }],
  ])
  let selected = "root-a"
  const dispose = plugin.setup({
    ui: { router: { current: () => selected ? { type: "session", sessionID: selected } : { type: "home" } } },
    data: { session: {
      get: (id) => sessions.get(id),
      root: (id) => sessions.get(id)?.parentID ?? id,
    } },
  })
  t.after(async () => {
    await dispose()
    for (const socket of sockets) socket.destroy()
    await new Promise((resolve) => server.close(resolve))
    await rm(directory, { recursive: true, force: true })
    for (const [key, value] of Object.entries(previous)) {
      if (value === undefined) delete process.env[key]
      else process.env[key] = value
    }
  })
  return {
    requests, sessions, dispose,
    select: (id) => { selected = id },
    title: () => requests.at(-1)?.params.tokens.opencode_subject,
  }
}

test("reports the full root subject, follows renames and switches, and isolates other sessions", async (t) => {
  const app = await fixture(t)
  await waitFor(() => app.title() === "Fix checkout validation")
  assert.equal(app.requests[0].method, "pane.report_metadata")
  assert.equal(app.requests[0].params.pane_id, "w1:p1")
  assert.equal(app.requests[0].params.source, "local:opencode-subject")
  assert.ok(app.requests[0].params.ttl_ms > 0)
  app.select("child-a")
  app.sessions.get("root-b").title = "Other pane's subject"
  await sleep(350)
  assert.equal(app.requests.length, 1)
  const longTitle = "Checkout validation: " + "details ".repeat(20)
  app.sessions.get("root-a").title = longTitle
  await waitFor(() => app.title() === longTitle)
  app.select("root-b")
  await waitFor(() => app.title() === "Other pane's subject")
  app.select(null)
  await waitFor(() => app.title() === null)
})

test("clears stale titles before hydration, retries failed reports, and clears on disposal", async (t) => {
  const app = await fixture(t, 1)
  app.select("unloaded")
  await waitFor(() => app.requests.length >= 2 && app.title() === null)
  assert.ok(app.requests.every(({ params }) => params.tokens.opencode_subject === null))
  app.sessions.set("unloaded", { title: "Freshly loaded session" })
  await waitFor(() => app.title() === "Freshly loaded session")
  await app.dispose()
  assert.equal(app.title(), null)
  const count = app.requests.length
  app.select("root-a")
  await sleep(350)
  assert.equal(app.requests.length, count)
})
