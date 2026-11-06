import assert from "node:assert/strict"
import { test } from "node:test"
import { formatTranscript } from "../../../dot_config/opencode2/extensions/temp-export/transcript.ts"

const session = { id: "ses_export", title: "Custom export", time: { created: 0, updated: 200_000 } }
const options = { timestamps: true, turnDuration: true, thinking: false, toolDetails: false, assistantMetadata: true }
const user = (id, created, text) => ({ type: "user", id, time: { created }, text })
const assistant = (id, created, completed, content) => ({
  type: "assistant", id, agent: "build", model: { providerID: "openai", id: "gpt-6-astra" },
  time: { created, completed }, content,
})
const text = (text) => ({ type: "text", text })
const idle = (id, created) => ({ type: "idle", id, time: { created }, outcome: "succeeded" })

test("preserves metadata, sorts messages and sums steps across hidden tools without exporting them", () => {
  const messages = [
    assistant("msg_c", 5_000, 9_500, [text("Answer")]),
    user("msg_a", 1_000, "Question"),
    assistant("msg_b", 2_000, 4_000, [
      { type: "reasoning", text: "Hidden thinking" },
      { type: "tool", name: "read", state: { status: "completed", input: { path: "a.ts" }, content: [text("Hidden output")] } },
    ]),
    { type: "synthetic", id: "msg_s", time: { created: 3_000 }, text: "Internal instruction" },
    idle("msg_d", 9_600),
  ]
  const output = formatTranscript(session, messages, options)
  assert.match(output, /^# Custom export\n\n\*\*Session ID:\*\* ses_export/)
  assert.ok(output.includes(new Date(1_000).toLocaleString()))
  assert.match(output, /## Assistant \(build · openai\/gpt-6-astra · .* · 4\.5s\)/)
  assert.ok(output.indexOf("Question") < output.indexOf("Answer"))
  assert.match(output, /Answer\n\n\*\*Time elapsed:\*\* 7\.5s/)
  assert.doesNotMatch(output, /Hidden|Internal instruction|\*\*Tool:/)
  assert.equal(messages[0].id, "msg_c", "formatting must not mutate the input")
})

test("idle markers define v2 turns even when a user steers an active turn", () => {
  const output = formatTranscript(session, [
    user("msg_1", 0, "Start"), assistant("msg_2", 1_000, 3_000, [text("First step")]),
    user("msg_3", 4_000, "Also do this"), assistant("msg_4", 5_000, 9_000, [text("Finished")]),
    idle("msg_5", 10_000),
    user("msg_6", 11_000, "Next"), assistant("msg_7", 12_000, 13_000, [text("Next answer")]), idle("msg_8", 14_000),
  ], options)
  assert.equal(output.match(/\*\*Time elapsed:\*\*/g).length, 2)
  assert.match(output, /Finished\n\n\*\*Time elapsed:\*\* 8\.0s/)
  assert.match(output, /Next answer\n\n\*\*Time elapsed:\*\* 1\.0s/)
})

test("legacy sessions use user boundaries and unfinished responses have no made-up duration", () => {
  const output = formatTranscript(session, [
    user("msg_1", 0, "First"), assistant("msg_2", 1_000, 62_000, [text("Done")]),
    user("msg_3", 63_000, "Second"), assistant("msg_4", 64_000, undefined, [text("Still working")]),
  ], options)
  assert.match(output, /\*\*Time elapsed:\*\* 1m 1s/)
  assert.equal(output.match(/\*\*Time elapsed:\*\*/g).length, 1)
})

test("optional reasoning and v2 tool content/errors work without timestamps or metadata", () => {
  const output = formatTranscript({ ...session, title: undefined }, [assistant("msg_1", 0, 100, [
    { type: "reasoning", text: "Reasoning" },
    { type: "tool", name: "read", state: { status: "completed", input: { path: "a.ts" }, content: [text("File contents")] } },
    { type: "tool", name: "shell", state: { status: "error", input: { command: "false" }, error: { message: "Command failed" } } },
  ])], { ...options, timestamps: false, turnDuration: false, thinking: true, toolDetails: true, assistantMetadata: false })
  assert.match(output, /^# Untitled session/)
  assert.match(output, /## Assistant\n/)
  assert.match(output, /_Thinking:_\n\nReasoning/)
  assert.match(output, /\*\*Tool: read\*\*/)
  assert.match(output, /File contents/)
  assert.match(output, /\*\*Error:\*\*\n```\nCommand failed/)
  assert.doesNotMatch(output, /openai|Time elapsed/)
})
