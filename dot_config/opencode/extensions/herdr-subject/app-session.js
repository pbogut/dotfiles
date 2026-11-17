import { spawn } from "node:child_process"
import { fileURLToPath } from "node:url"

const document = "pbogut-opencode"
const roleOf = (name) => name === "opencode" ? "oc-1" : /^oc-[1-9][0-9]*$/.test(name) ? name : null
const validID = (id) => typeof id === "string" && id.length > 0 && id.length <= 256 && !/[\r\n\0]/.test(id)

// hc resolves HC_SOCKET / HC_SESSION itself, including isolated test cores.
export function core(method, params) {
  return new Promise((resolve, reject) => {
    const child = spawn("hc", ["connect"], { stdio: ["pipe", "pipe", "pipe"] })
    let input = ""
    let error = ""
    let finished = false
    const timer = setTimeout(() => finish(new Error(`Herdr Core timed out: ${method}`)), 3000)
    function finish(error, result) {
      if (finished) return
      finished = true
      clearTimeout(timer)
      child.kill()
      if (error) reject(error)
      else resolve(result)
    }
    child.stdout.on("data", (chunk) => {
      input += chunk
      const end = input.indexOf("\n")
      if (end < 0) return
      try {
        const response = JSON.parse(input.slice(0, end))
        if (response.error) {
          const error = new Error(response.error.message)
          error.kind = response.error.data?.kind
          finish(error)
        } else finish(null, response.result)
      } catch (error) { finish(error) }
    })
    child.stderr.on("data", (chunk) => { error += chunk })
    child.on("error", finish)
    child.on("close", (code) => finish(new Error(error || `hc connect exited: ${code}`)))
    child.stdin.on("error", finish)
    child.stdin.write(`${JSON.stringify({ jsonrpc: "2.0", id: 1, method, params })}\n`)
  })
}

async function updateSlot(space, role, update, rpc) {
  const key = `${space}/${role}`
  for (let attempt = 0; attempt < 5; attempt++) {
    const snapshot = await rpc("doc.get", { name: document })
    const slots = snapshot.value?.slots ?? {}
    const value = update(slots[key])
    if (value === undefined) return
    if (value === slots[key]) return value
    try {
      await rpc("doc.set", {
        name: document, version: snapshot.version, value: { slots: { ...slots, [key]: value } },
      })
      return value
    } catch (error) {
      if (error.kind !== "conflict") throw error
    }
  }
  throw new Error("OpenCode session storage kept changing. Try again.")
}

export async function prepare(terminalID, space, role, folder, rpc = core) {
  if (!terminalID || !space || roleOf(role) !== role) throw new Error("Missing named OpenCode tab")
  const terminal = await rpc("terminal.get", { terminal: terminalID })
  if (terminal.state !== "live" || terminal.labels["herdr.space"] !== space || !terminal.labels["herdr.tab"]) {
    throw new Error("OpenCode must run in its Herdr App space")
  }
  const saved = await updateSlot(space, role, (previous) => ({
    sessionID: validID(previous?.sessionID) ? previous.sessionID : null,
    terminal: terminalID,
  }), rpc)
  await rpc("terminal.label", { terminal: terminalID, labels: {
    "pbogut.oc.role": role, "pbogut.oc.pid": String(terminal.pid), "pbogut.oc.folder": folder,
  } })
  return saved.sessionID
}

export async function adopt(terminalID, rpc = core) {
  const terminal = await rpc("terminal.get", { terminal: terminalID })
  if (terminal.state !== "live") return false
  if (roleOf(terminal.labels["pbogut.oc.role"])) return true
  const layout = await rpc("doc.get", { name: "herdr-app" })
  const space = layout.value?.spaces?.find((item) => item.id === terminal.labels["herdr.space"])
  const tab = space?.tabs?.find((item) => item.id === terminal.labels["herdr.tab"])
  const role = roleOf(tab?.name)
  if (!role) return false
  const saved = await rpc("doc.get", { name: document })
  const owner = saved.value?.slots?.[`${space.id}/${role}`]?.terminal
  if (owner && owner !== terminalID) {
    try {
      if ((await rpc("terminal.get", { terminal: owner })).state === "live") return false
    } catch (error) {
      if (error.kind !== "not_found") throw error
    }
  }
  await prepare(terminalID, space.id, role, space.folder || terminal.cwd, rpc)
  return true
}

export async function reportSession(terminalID, sessionID, rpc = core, isCurrent = () => true) {
  if (!validID(sessionID)) return
  const terminal = await rpc("terminal.get", { terminal: terminalID })
  const space = terminal.labels["herdr.space"]
  const role = roleOf(terminal.labels["pbogut.oc.role"])
  if (!space || !role || terminal.state !== "live" || terminal.labels["pbogut.oc.pid"] !== String(terminal.pid)) return
  const layout = await rpc("doc.get", { name: "herdr-app" })
  const tab = layout.value?.spaces?.find((item) => item.id === space)?.tabs
    ?.find((item) => item.id === terminal.labels["herdr.tab"])
  if (roleOf(tab?.name) !== role) return
  return updateSlot(space, role, (previous) => {
    if (!isCurrent() || previous?.terminal !== terminalID) return
    if (previous.sessionID === sessionID) return previous
    return { ...previous, sessionID }
  }, rpc)
}

export function trackSession(ctx, terminalID = process.env.HC_TERMINAL_ID, rpc = core) {
  let disposed = false
  let delivered
  let refreshAt = 0
  let retryAt = 0
  let attached = false
  let pending
  function selected() {
    const route = ctx.ui.router.current()
    if (route.type !== "session") return null
    const root = ctx.data.session.root(route.sessionID)
    return root && ctx.data.session.get(root) ? root : null
  }
  function sync() {
    if (disposed || pending || Date.now() < retryAt) return
    const sessionID = selected()
    // Home and plugin routes retain the last conversation, as in the old TUI.
    if (!sessionID || (sessionID === delivered && Date.now() < refreshAt)) return
    pending = (async () => {
      if (!attached) attached = await adopt(terminalID, rpc)
      if (!attached) {
        retryAt = Date.now() + 5000
        return
      }
      return reportSession(terminalID, sessionID, rpc, () => !disposed && selected() === sessionID)
    })()
      .then((saved) => {
        if (!saved) return
        delivered = sessionID
        refreshAt = Date.now() + 5000
      }).catch(() => {}).finally(() => { pending = undefined })
  }
  const timer = setInterval(sync, 250)
  timer.unref()
  sync()
  return async () => {
    if (disposed) return
    disposed = true
    clearInterval(timer)
    await pending
  }
}

export async function recovery(terminalID, shellPID, rpc = core) {
  if (!terminalID) return
  const terminal = await rpc("terminal.get", { terminal: terminalID })
  const labels = terminal.labels
  const role = roleOf(labels["pbogut.oc.role"])
  const space = labels["herdr.space"]
  // Only the new root shell may restore. Nested shells and the original
  // launcher's `zsh -ic` cannot consume the recovery marker.
  if (!role || !space || terminal.state !== "live" || String(terminal.pid) !== shellPID ||
      !labels["pbogut.oc.pid"] || labels["pbogut.oc.pid"] === shellPID) return
  const layout = await rpc("doc.get", { name: "herdr-app" })
  const tab = layout.value?.spaces?.find((item) => item.id === space)?.tabs
    ?.find((item) => item.id === labels["herdr.tab"])
  if (roleOf(tab?.name) !== role) return
  const saved = await rpc("doc.get", { name: document })
  if (saved.value?.slots?.[`${space}/${role}`]?.terminal !== terminalID) return
  return { space, role, folder: labels["pbogut.oc.folder"] }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try {
    const [action, first, second] = process.argv.slice(2)
    if (action === "prepare") {
      const session = await prepare(process.env.HC_TERMINAL_ID, first, second, process.cwd())
      process.stdout.write(session ?? "")
    } else if (action === "recover") {
      const target = await recovery(process.env.HC_TERMINAL_ID, first)
      if (target) process.stdout.write([target.space, target.role, target.folder].join("\0"))
    } else throw new Error("Expected prepare or recover")
  } catch (error) {
    console.error(`OpenCode restoration: ${error.message}`)
    process.exitCode = 1
  }
}
