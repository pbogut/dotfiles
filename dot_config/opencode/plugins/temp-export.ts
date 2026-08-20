import type { Message, Part, Session } from "@opencode-ai/sdk/v2"
import type { TuiPlugin, TuiPluginModule } from "@opencode-ai/plugin/tui"
import { spawn } from "node:child_process"
import { mkdtemp, rm, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import path from "node:path"

const command = "session.temp-export"

function formatDuration(milliseconds: number) {
  if (milliseconds < 1000) return `${milliseconds}ms`
  if (milliseconds < 60_000) return `${(milliseconds / 1000).toFixed(1)}s`
  if (milliseconds < 3_600_000) {
    const minutes = Math.floor(milliseconds / 60_000)
    const seconds = Math.floor((milliseconds % 60_000) / 1000)
    return `${minutes}m ${seconds}s`
  }
  const hours = Math.floor(milliseconds / 3_600_000)
  const minutes = Math.floor((milliseconds % 3_600_000) / 60_000)
  return `${hours}h ${minutes}m`
}

function formatPart(part: Part, includeThinking: boolean, includeToolDetails: boolean) {
  if (part.type === "text" && !part.synthetic) return `${part.text}\n\n`
  if (part.type === "reasoning") return includeThinking ? `_Thinking:_\n\n${part.text}\n\n` : ""
  if (part.type !== "tool") return ""
  if (!includeToolDetails) return ""

  let result = `**Tool: ${part.tool}**\n`
  if (part.state.input) {
    result += `\n**Input:**\n\`\`\`json\n${JSON.stringify(part.state.input, null, 2)}\n\`\`\`\n`
  }
  if (part.state.status === "completed" && part.state.output) {
    result += `\n**Output:**\n\`\`\`\n${part.state.output}\n\`\`\`\n`
  }
  if (part.state.status === "error" && part.state.error) {
    result += `\n**Error:**\n\`\`\`\n${part.state.error}\n\`\`\`\n`
  }
  return `${result}\n`
}

function formatTranscript(
  session: Session,
  messages: readonly Message[],
  parts: (messageID: string) => readonly Part[],
  includeTimestamps: boolean,
  includeTurnDuration: boolean,
  includeThinking: boolean,
  includeToolDetails: boolean,
  includeAssistantMetadata: boolean,
) {
  let transcript = `# ${session.title}\n\n`
  transcript += `**Session ID:** ${session.id}\n`
  transcript += `**Created:** ${new Date(session.time.created).toLocaleString()}\n`
  transcript += `**Updated:** ${new Date(session.time.updated).toLocaleString()}\n\n---\n\n`

  const blocks: string[] = []
  let turnMessages: Array<Extract<Message, { role: "assistant" }>> = []
  let lastAssistantBlock: number | undefined

  const finishTurn = () => {
    if (!includeTurnDuration || turnMessages.length === 0) return

    const start = Math.min(...turnMessages.map((message) => message.time.created))
    const completed = turnMessages.flatMap((message) =>
      message.time.completed === undefined ? [] : [message.time.completed],
    )
    if (completed.length === 0) return

    const end = Math.max(...completed)
    if (end < start) return

    const elapsed = `**Time elapsed:** ${formatDuration(end - start)}`
    const block = lastAssistantBlock === undefined ? undefined : blocks[lastAssistantBlock]
    if (lastAssistantBlock !== undefined && block !== undefined) {
      blocks[lastAssistantBlock] = `${block.trimEnd()}\n\n${elapsed}`
    } else {
      blocks.push(elapsed)
    }
  }

  for (const message of messages.toSorted(
    (left, right) => left.time.created - right.time.created || left.id.localeCompare(right.id),
  )) {
    if (message.role === "user") {
      finishTurn()
      turnMessages = []
      lastAssistantBlock = undefined
    } else {
      turnMessages.push(message)
    }

    const body = parts(message.id)
      .map((part) => formatPart(part, includeThinking, includeToolDetails))
      .join("")
    if (!body.trim()) continue

    const details: string[] = []
    if (message.role === "user") {
      if (includeTimestamps) details.push(new Date(message.time.created).toLocaleString())
      blocks.push(`## User${details.length ? ` (${details.join(" · ")})` : ""}\n\n${body}`)
    } else {
      if (includeAssistantMetadata) details.push(message.agent, `${message.providerID}/${message.modelID}`)
      if (includeTimestamps) {
        details.push(new Date(message.time.created).toLocaleString())
        if (message.time.completed !== undefined) {
          details.push(formatDuration(Math.max(0, message.time.completed - message.time.created)))
        }
      }
      blocks.push(`## Assistant${details.length ? ` (${details.join(" · ")})` : ""}\n\n${body}`)
      lastAssistantBlock = blocks.length - 1
    }
  }
  finishTurn()

  if (blocks.length > 0) transcript += `${blocks.map((block) => block.trimEnd()).join("\n\n---\n\n")}\n\n---\n\n`

  return transcript
}

function runEditor(editor: string, file: string, cwd: string | undefined) {
  return new Promise<void>((resolve, reject) => {
    const [program, ...args] = editor.split(" ")
    const child = spawn(program!, [...args, file], {
      cwd,
      stdio: "inherit",
      shell: process.platform === "win32",
    })
    child.on("error", reject)
    child.on("exit", (code, signal) => {
      if (code === 0) return resolve()
      reject(new Error(`Editor exited with ${signal ? `signal ${signal}` : `code ${code}`}`))
    })
  })
}

const tui: TuiPlugin = async (api, options) => {
  const keybind = typeof options?.keybind === "string" ? options.keybind : "<leader>y"
  const includeTimestamps = typeof options?.timestamps === "boolean" ? options.timestamps : false
  const includeTurnDuration = typeof options?.turnDuration === "boolean" ? options.turnDuration : false
  const includeThinking = typeof options?.thinking === "boolean" ? options.thinking : true
  const includeToolDetails = typeof options?.toolDetails === "boolean" ? options.toolDetails : true
  const includeAssistantMetadata =
    typeof options?.assistantMetadata === "boolean" ? options.assistantMetadata : true

  api.keymap.registerLayer({
    commands: [
      {
        name: command,
        title: "Open session transcript in $EDITOR",
        category: "Session",
        namespace: "palette",
        enabled: () => api.route.current.name === "session",
        async run() {
          const route = api.route.current
          if (route.name !== "session") return

          const editor = process.env.EDITOR
          if (!editor) {
            api.ui.toast({ variant: "error", message: "$EDITOR is not set" })
            return
          }

          const session = api.state.session.get(route.params.sessionID)
          if (!session) return

          const directory = await mkdtemp(path.join(tmpdir(), "opencode-export-"))
          const file = path.join(directory, `session-${session.id.slice(0, 8)}.md`)
          const cwd = api.state.path.worktree === "/" ? api.state.path.directory : api.state.path.worktree
          let suspended = false

          try {
            const transcript = formatTranscript(
              session,
              api.state.session.messages(session.id),
              api.state.part,
              includeTimestamps,
              includeTurnDuration,
              includeThinking,
              includeToolDetails,
              includeAssistantMetadata,
            )
            await writeFile(file, transcript)
            api.renderer.suspend()
            suspended = true
            api.renderer.currentRenderBuffer.clear()
            await runEditor(editor, file, cwd || undefined)
          } catch (error) {
            api.ui.toast({
              variant: "error",
              message: error instanceof Error ? error.message : "Failed to open session transcript",
            })
          } finally {
            await rm(directory, { recursive: true, force: true }).catch(() => undefined)
            if (suspended) {
              api.renderer.currentRenderBuffer.clear()
              api.renderer.resume()
              api.renderer.requestRender()
            }
          }
        },
      },
    ],
    bindings: [
      {
        key: keybind,
        cmd: command,
        desc: "Open session transcript in $EDITOR",
      },
    ],
  })
}

export default {
  id: "temp-export",
  tui,
} satisfies TuiPluginModule
