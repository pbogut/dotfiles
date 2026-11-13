import assert from "node:assert/strict"
import { test } from "node:test"
import plugin from "../../../dot_config/opencode/plugins/agent-switch/index.ts"

async function fixture({ agent = "plan", assertPermission = async () => {} } = {}) {
  let tool, contextHook
  const permissions = [], switches = []
  await plugin.setup({
    tool: { transform: async (register) => register({ add: (value) => { tool = value } }) },
    permission: { assert: async (request) => {
      permissions.push(request)
      await assertPermission(request)
    } },
    session: {
      get: async () => ({ agent }),
      switchAgent: async (request) => { switches.push(request); agent = request.agent },
      hook: async (name, callback) => { assert.equal(name, "context"); contextHook = callback },
    },
  })
  return {
    tool, contextHook, permissions, switches,
    run: (destination) => tool.execute({ agent: destination }, {
      sessionID: "ses_test", agent, messageID: "msg_test", id: "call_test",
    }),
  }
}

test("Build waits for approval before changing the current session", async () => {
  let approve, requested
  const ready = new Promise((resolve) => { requested = resolve })
  const app = await fixture({ assertPermission: () => {
    requested()
    return new Promise((resolve) => { approve = resolve })
  } })
  const pending = app.run("build")
  await ready
  assert.deepEqual(app.switches, [])
  assert.deepEqual(app.permissions, [{
    sessionID: "ses_test", agent: "plan",
    source: { type: "tool", messageID: "msg_test", id: "call_test" },
    action: "switch_agent", resources: ["build"], save: [],
  }])
  approve()
  await pending
  assert.deepEqual(app.switches, [{ sessionID: "ses_test", agent: "build" }])
})

test("Plan also checks destination permission, so it can be configured to ask", async () => {
  let approve, requested
  const ready = new Promise((resolve) => { requested = resolve })
  const app = await fixture({ agent: "build", assertPermission: () => {
    requested()
    return new Promise((resolve) => { approve = resolve })
  } })
  const pending = app.run("plan")
  await ready
  assert.deepEqual(app.switches, [])
  assert.equal(app.permissions[0].action, "switch_agent")
  assert.deepEqual(app.permissions[0].resources, ["plan"])
  approve()
  await pending
  assert.deepEqual(app.switches, [{ sessionID: "ses_test", agent: "plan" }])
})

test("rejection and denial propagate unchanged without switching or retrying", async () => {
  for (const agent of ["plan", "build"]) {
    const rejection = new Error("Rejected")
    const app = await fixture({ agent, assertPermission: async () => { throw rejection } })
    await assert.rejects(app.run(agent === "plan" ? "build" : "plan"), (error) => error === rejection)
    assert.deepEqual(app.switches, [])
    assert.equal(app.permissions.length, 1)
  }
})

test("switching from another primary agent still uses only the destination resource", async () => {
  const app = await fixture({ agent: "chat" })
  await app.run("build")
  assert.deepEqual(app.permissions[0].resources, ["build"])
  assert.deepEqual(app.switches, [{ sessionID: "ses_test", agent: "build" }])
})

test("an already-selected destination is a no-op; other destinations are rejected", async () => {
  const app = await fixture()
  await app.run("plan")
  await assert.rejects(app.run("explore"), /Choose plan or build/)
  assert.deepEqual(app.permissions, [])
  assert.deepEqual(app.switches, [])
  assert.equal(app.tool.options.codemode, false)
})

const reminder = `<system-reminder>
You are in Plan mode. Discuss the plan with the user directly in the conversation. Do not create or update plan files unless the user explicitly asks you to; when they do, write them only in:
/home/example/.opencode/plan

Do not modify any other files or ask a subagent to do so.

You remain in Plan mode until the user switches agents. If the user asks you to implement changes, do not do so. Tell them they need to switch agents.
</system-reminder>`
const message = (text, role = "user") => ({ role, content: [{ type: "text", text }] })

test("only the standalone stock Plan reminder is adapted, preserving review and edit restrictions", async () => {
  const app = await fixture()
  const original = message(reminder)
  const quoted = message(`Explain this reminder:\n${reminder}`)
  const assistant = message(reminder, "assistant")
  const tool = { role: "tool", content: [{ type: "tool-result", id: "result", name: "read", result: { type: "text", value: reminder } }] }
  const event = { agent: "plan", messages: [original, quoted, assistant, tool], system: [] }
  app.contextHook(event)
  assert.equal(original.content[0].text, reminder)
  assert.equal(event.messages[1], quoted)
  assert.equal(event.messages[2], assistant)
  assert.equal(event.messages[3], tool)
  const updated = event.messages[0].content[0].text
  assert.match(updated, /\/home\/example\/\.opencode\/plan/)
  assert.match(updated, /Do not modify any other files or ask a subagent to do so\./)
  assert.match(updated, /explicitly approves implementation/)
  assert.match(updated, /Review feedback is for discussion/)
  assert.doesNotMatch(updated, /Tell them they need to switch agents/)
})

test("the provider's manual-switch instruction is adapted only during Plan", async () => {
  const app = await fixture()
  const text = "Keep other instructions. If the user asks you to implement changes, inform them that `plan` mode is active and that they need to switch to build mode."
  for (const agent of ["plan", "build", "general"]) {
    const system = { type: "text", text }
    const event = { agent, messages: [], system: [system] }
    app.contextHook(event)
    assert.equal(system.text, text)
    if (agent === "plan") {
      assert.match(event.system[0].text, /^Keep other instructions\./)
      assert.doesNotMatch(event.system[0].text, /inform them that/)
    } else {
      assert.equal(event.system[0].text, text)
    }
    assert.equal(event.system.length, agent === "general" ? 1 : 2)
  }
})
