import type { Context } from "@opencode/plugin/tui/context"
import { spawn } from "node:child_process"
import { mkdtemp, rm, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import path from "node:path"
import { formatTranscript, type TranscriptOptions } from "./transcript.ts"

const command = "session.temp-export"

function runEditor(editor: string, file: string, cwd: string) {
  return new Promise<void>((resolve, reject) => {
    // EDITOR is a user-configured shell command. Keep the generated path out of
    // shell source so quoted arguments and temporary paths with spaces work.
    const child = spawn("/bin/sh", ["-c", `exec ${editor} "$1"`, "opencode-temp-export", file], {
      cwd,
      stdio: "inherit",
    })
    child.once("error", reject)
    child.once("exit", (code, signal) => {
      if (code === 0) resolve()
      else reject(new Error(`Editor exited with ${signal ? `signal ${signal}` : `code ${code}`}`))
    })
  })
}

export default {
  id: "temp-export",
  setup(ctx: Context) {
    const option = (name: string, fallback: boolean) => typeof ctx.options[name] === "boolean" ? ctx.options[name] : fallback
    const options: TranscriptOptions = {
      timestamps: option("timestamps", false),
      turnDuration: option("turnDuration", false),
      thinking: option("thinking", true),
      toolDetails: option("toolDetails", true),
      assistantMetadata: option("assistantMetadata", true),
    }
    const keybind = typeof ctx.options.keybind === "string" ? ctx.options.keybind : "<leader>y"
    let running = false
    ctx.keymap.layer(() => ({
      commands: [{
        id: command,
        title: "Open session transcript in $EDITOR",
        group: "Session",
        palette: true,
        bind: keybind,
        enabled: () => !running && ctx.ui.router.current().type === "session",
        async run() {
          const route = ctx.ui.router.current()
          if (running || route.type !== "session") return
          const editor = process.env.EDITOR?.trim()
          if (!editor) {
            ctx.ui.toast.show({ variant: "error", message: "$EDITOR is not set" })
            return
          }

          running = true
          let directory: string | undefined
          let suspended = false
          let failure: unknown
          try {
            // Fetch the complete transcript rather than the TUI's paginated cache.
            const { info, messages } = await ctx.client.experimental.session.export({ sessionID: route.sessionID })
            const transcript = formatTranscript(info, messages, options)
            directory = await mkdtemp(path.join(tmpdir(), "opencode-export-"))
            const file = path.join(directory, `session-${info.id.slice(0, 8)}.md`)
            await writeFile(file, transcript, { mode: 0o600 })
            ctx.ui.dialog.clear()
            suspended = true
            await ctx.renderer.suspend()
            const cwd = info.location.directory === "/" ? process.cwd() : info.location.directory
            await runEditor(editor, file, cwd)
          } catch (error) {
            failure = error
          } finally {
            if (directory) await rm(directory, { recursive: true, force: true }).catch((error) => { failure ??= error })
            if (suspended) {
              try {
                await ctx.renderer.resume()
                ctx.renderer.requestRender()
              } catch (error) {
                failure ??= error
              }
            }
            running = false
          }
          if (failure) {
            ctx.ui.toast.show({
              variant: "error",
              message: failure instanceof Error ? failure.message : "Failed to open session transcript",
            })
          }
        },
      }],
      bindings: [command],
    }))
  },
}
