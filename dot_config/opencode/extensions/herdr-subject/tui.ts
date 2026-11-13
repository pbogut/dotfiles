import type { Context } from "@opencode/plugin/tui/context"
import net from "node:net"

export default {
  id: "pbogut.herdr-subject",
  setup(ctx: Context) {
    const paneID = process.env.HERDR_PANE_ID
    const socketPath = process.env.HERDR_SOCKET_PATH
    if (process.env.HERDR_ENV !== "1" || !paneID || !socketPath) return

    let disposed = false
    let delivered: string | null | undefined
    let refreshAt = 0
    let sequence = Date.now() * 1000
    let pending: Promise<void> | undefined

    function subject() {
      const route = ctx.ui.router.current()
      if (route.type !== "session") return null
      const rootID = ctx.data.session.root(route.sessionID)
      return rootID ? ctx.data.session.get(rootID)?.title ?? null : null
    }

    function report(title: string | null, isCurrent = () => true) {
      return new Promise<boolean>((resolve) => {
        let settled = false
        let input = ""
        const socket = net.createConnection(socketPath!, () => {
          if (!isCurrent()) return finish(false)
          socket.write(`${JSON.stringify({
            id: `opencode-subject:${++sequence}`,
            method: "pane.report_metadata",
            params: {
              pane_id: paneID,
              source: "local:opencode-subject",
              tokens: { opencode_subject: title },
              seq: sequence,
              ttl_ms: 15_000,
            },
          })}\n`)
        })
        const timeout = setTimeout(() => finish(false), 1000)
        timeout.unref()
        function finish(ok: boolean) {
          if (settled) return
          settled = true
          clearTimeout(timeout)
          socket.destroy()
          resolve(ok)
        }
        socket.on("data", (chunk) => {
          input += chunk
          if (!input.includes("\n")) return
          try {
            const response = JSON.parse(input.slice(0, input.indexOf("\n")))
            finish(response.result !== undefined && !response.error)
          } catch {
            finish(false)
          }
        })
        socket.on("error", () => finish(false))
        socket.on("close", () => finish(false))
      })
    }

    function sync() {
      if (disposed || pending) return
      const title = subject()
      if (title === delivered && Date.now() < refreshAt) return
      pending = report(title, () => !disposed && title === subject()).then((ok) => {
        if (!ok) return
        delivered = title
        refreshAt = Date.now() + 5000
      }).finally(() => { pending = undefined })
    }

    // Poll the local cache for route changes and title hydration. Refresh the
    // expiring metadata so an abruptly closed TUI cannot leave a stale subject.
    const timer = setInterval(sync, 250)
    timer.unref()
    sync()
    return async () => {
      if (disposed) return
      disposed = true
      clearInterval(timer)
      await pending
      await report(null)
    }
  },
}
