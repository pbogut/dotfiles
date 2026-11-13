import type { Plugin } from "@opencode/plugin"

const manualSwitch = "You remain in Plan mode until the user switches agents. If the user asks you to implement changes, do not do so. Tell them they need to switch agents."
const approvedSwitch = "You remain in Plan mode until the user switches agents or switch_agent succeeds. After the user explicitly approves implementation, call switch_agent with agent build to request the switch. Wait until the next model turn after the tool succeeds before implementing. Review feedback is for discussion and does not authorize requesting Build."
const manualSwitchBase = "If the user asks you to implement changes, inform them that `plan` mode is active and that they need to switch to build mode."

const workflow = `Agent switching:
- In Build, finish implementation and verification, then use switch_agent with agent plan before reviewing changes, opening a human review, or handing completed work back to the user. Routine implementation checks stay in Build.
- In Plan, discuss review feedback, including requests for corrections. Feedback alone never authorizes requesting Build. Wait for the user's explicit approval to implement, then use switch_agent with agent build.
- Acceptance of an increment permits requesting Build for the next already-agreed increment. If the task is complete, stay in Plan.
- Call switch_agent alone. Do not batch or parallelize it with other tools. Continue the approved work on the next model turn after it succeeds, using the destination agent's instructions and permissions.
- If a switch is rejected or denied, stay in the current mode and discuss or wait. Do not retry without a new explicit instruction from the user.`

export default {
  id: "agent-switch",
  async setup(ctx) {
    await ctx.tool.transform((editor) => {
      editor.add({
        name: "switch_agent",
        description: "Switch the current session to Plan for review or to Build after explicit implementation approval. Review feedback alone is not approval. Call this tool alone; continue work on the next model turn after it succeeds.",
        input: {
          type: "object",
          properties: { agent: { type: "string", enum: ["plan", "build"] } },
          required: ["agent"],
          additionalProperties: false,
        },
        options: { codemode: false },
        execute: async (input, context) => {
          const { agent } = input as { agent: string }
          if (agent !== "plan" && agent !== "build") throw new Error("Choose plan or build.")
          const session = await ctx.session.get({ sessionID: context.sessionID })
          if (session.agent === agent) return { content: `Already in ${agent} mode.` }

          await ctx.permission.assert({
            sessionID: context.sessionID,
            agent: context.agent,
            source: { type: "tool", messageID: context.messageID, id: context.id },
            action: "switch_agent",
            resources: [agent],
            save: [],
          })
          await ctx.session.switchAgent({ sessionID: context.sessionID, agent })
          return {
            content: agent === "plan"
              ? "Switched to Plan. Continue the review or discussion on the next model turn. Feedback does not authorize implementation."
              : "Switched to Build. Continue the explicitly approved implementation on the next model turn without waiting for another user message.",
          }
        },
      })
    })

    await ctx.session.hook("context", (event) => {
      if (event.agent !== "plan" && event.agent !== "build") return
      if (event.agent === "plan") {
        // Core's Plan reminder is a standalone user message. Change only its
        // manual-switch instruction in this request, not the stored transcript.
        event.messages = event.messages.map((message) => {
          if (message.role !== "user" || message.content.length !== 1) return message
          const part = message.content[0]
          if (part?.type !== "text" || !part.text.startsWith("<system-reminder>\nYou are in Plan mode.") || !part.text.endsWith("\n</system-reminder>")) return message
          return { ...message, content: [{ ...part, text: part.text.replace(manualSwitch, approvedSwitch) }] }
        })
        event.system = event.system.map((part) => ({
          ...part,
          text: part.text.replace(manualSwitchBase, approvedSwitch),
        }))
      }
      event.system.push({ type: "text", text: workflow })
    })
  },
} satisfies Plugin.Plugin
