import type { SessionInfo, SessionMessageInfo } from "@opencode/client"

export interface TranscriptOptions {
  timestamps: boolean
  turnDuration: boolean
  thinking: boolean
  toolDetails: boolean
  assistantMetadata: boolean
}

type Assistant = Extract<SessionMessageInfo, { type: "assistant" }>

function formatDuration(milliseconds: number) {
  if (milliseconds < 1000) return `${milliseconds}ms`
  if (milliseconds < 60_000) return `${(milliseconds / 1000).toFixed(1)}s`
  if (milliseconds < 3_600_000) {
    return `${Math.floor(milliseconds / 60_000)}m ${Math.floor((milliseconds % 60_000) / 1000)}s`
  }
  return `${Math.floor(milliseconds / 3_600_000)}h ${Math.floor((milliseconds % 3_600_000) / 60_000)}m`
}

function formatPart(part: Assistant["content"][number], options: TranscriptOptions) {
  if (part.type === "text") return `${part.text}\n\n`
  if (part.type === "reasoning") return options.thinking ? `_Thinking:_\n\n${part.text}\n\n` : ""
  if (!options.toolDetails) return ""

  let result = `**Tool: ${part.name}**\n`
  if (part.state.input) result += `\n**Input:**\n\`\`\`json\n${JSON.stringify(part.state.input, null, 2)}\n\`\`\`\n`
  if (part.state.status === "completed") {
    const output = part.state.content.filter((item) => item.type === "text").map((item) => item.text).join("\n")
    if (output) result += `\n**Output:**\n\`\`\`\n${output}\n\`\`\`\n`
  }
  if (part.state.status === "error") {
    result += `\n**Error:**\n\`\`\`\n${part.state.error.message}\n\`\`\`\n`
  }
  return `${result}\n`
}

export function formatTranscript(session: SessionInfo, messages: readonly SessionMessageInfo[], options: TranscriptOptions) {
  let transcript = `# ${session.title ?? "Untitled session"}\n\n`
  transcript += `**Session ID:** ${session.id}\n`
  transcript += `**Created:** ${new Date(session.time.created).toLocaleString()}\n`
  transcript += `**Updated:** ${new Date(session.time.updated).toLocaleString()}\n\n---\n\n`

  const blocks: string[] = []
  const legacyTurns = !messages.some((message) => message.type === "idle")
  let start: number | undefined
  let end: number | undefined
  let lastAssistantBlock: number | undefined
  const finishTurn = () => {
    if (options.turnDuration && start !== undefined && end !== undefined && end >= start) {
      const elapsed = `**Time elapsed:** ${formatDuration(end - start)}`
      if (lastAssistantBlock === undefined) blocks.push(elapsed)
      else blocks[lastAssistantBlock] = `${blocks[lastAssistantBlock]!.trimEnd()}\n\n${elapsed}`
    }
    start = end = lastAssistantBlock = undefined
  }

  for (const message of messages.toSorted((a, b) => a.time.created - b.time.created || a.id.localeCompare(b.id))) {
    if (message.type === "idle") {
      finishTurn()
      continue
    }
    if (message.type !== "user" && message.type !== "assistant") continue
    if (message.type === "user" && legacyTurns) finishTurn()
    if (message.type === "assistant") {
      start ??= message.time.created
      if (message.time.completed !== undefined) end = Math.max(end ?? message.time.completed, message.time.completed)
    }
    const body = message.type === "user"
      ? `${message.text}\n\n`
      : message.content.map((part) => formatPart(part, options)).join("")
    if (!body.trim()) continue

    const details: string[] = []
    if (message.type === "assistant" && options.assistantMetadata) {
      details.push(message.agent, `${message.model.providerID}/${message.model.id}`)
    }
    if (options.timestamps) {
      details.push(new Date(message.time.created).toLocaleString())
      if (message.type === "assistant" && message.time.completed !== undefined) {
        details.push(formatDuration(Math.max(0, message.time.completed - message.time.created)))
      }
    }
    const role = message.type === "user" ? "User" : "Assistant"
    blocks.push(`## ${role}${details.length ? ` (${details.join(" · ")})` : ""}\n\n${body}`)
    if (message.type === "assistant") lastAssistantBlock = blocks.length - 1
  }
  finishTurn()
  if (blocks.length) transcript += `${blocks.map((block) => block.trimEnd()).join("\n\n---\n\n")}\n\n---\n\n`
  return transcript
}
