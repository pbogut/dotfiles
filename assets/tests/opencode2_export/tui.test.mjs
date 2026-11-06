import assert from "node:assert/strict"
import { mkdtemp, mkdir, readFile, rm, stat, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import path from "node:path"
import { test } from "node:test"
import plugin from "../../../dot_config/opencode2/extensions/temp-export/tui.ts"

async function fixture(exitCode = 0) {
  const root = await mkdtemp(path.join(tmpdir(), "export test-"))
  const cwd = path.join(root, "project")
  await mkdir(cwd)
  const resultFile = path.join(root, "result.json")
  const editorFile = path.join(root, "editor.mjs")
  const suspendedFile = path.join(root, "suspended")
  await writeFile(editorFile, `
    import { existsSync, readFileSync, statSync, writeFileSync } from "node:fs";
    if (!existsSync(${JSON.stringify(suspendedFile)})) throw new Error("TUI not yet suspended");
    const file = process.argv[3];
    writeFileSync(${JSON.stringify(resultFile)}, JSON.stringify({
      file, body: readFileSync(file, "utf8"), mode: statSync(file).mode & 0o777,
      cwd: process.cwd(), args: process.argv.slice(2)
    }));
    process.exit(${exitCode});
  `)
  const originalEditor = process.env.EDITOR
  process.env.EDITOR = `${JSON.stringify(process.execPath)} ${JSON.stringify(editorFile)} "quoted argument"`
  const events = []
  const toasts = []
  const calls = []
  let layer
  let route = { type: "session", sessionID: "ses_fixture" }
  const ctx = {
    options: { timestamps: true, turnDuration: true, thinking: false, toolDetails: false, assistantMetadata: true },
    client: { experimental: { session: { export: async (input) => {
      calls.push(input)
      events.push("export")
      return {
        info: { id: "ses_fixture", title: "Full session", time: { created: 0, updated: 9_000 }, location: { directory: cwd } },
        messages: [
          { id: "msg_1", type: "user", text: "Old message outside the UI cache", time: { created: 1_000 } },
          { id: "msg_2", type: "assistant", agent: "build", model: { providerID: "openai", id: "gpt-6-astra" },
            time: { created: 2_000, completed: 9_000 }, content: [{ type: "reasoning", text: "Hidden" }, { type: "text", text: "Answer" }] },
        ],
      }
    } } } },
    keymap: { layer: (factory) => { layer = factory() } },
    ui: {
      router: { current: () => route },
      dialog: { clear: () => events.push("clear-dialog") },
      toast: { show: (toast) => { events.push("toast"); toasts.push(toast) } },
    },
    renderer: {
      suspend: async () => { events.push("suspend-start"); await writeFile(suspendedFile, "ready"); events.push("suspend-end") },
      resume: async () => { events.push("resume-start"); await rm(suspendedFile); events.push("resume-end") },
      requestRender: () => { assert.equal(events.at(-1), "resume-end"); events.push("render") },
    },
  }
  plugin.setup(ctx)
  return {
    ctx, events, toasts, calls, layer, command: layer.commands[0], cwd,
    setRoute(value) { route = value },
    result: async () => JSON.parse(await readFile(resultFile, "utf8")),
    async cleanup() {
      if (originalEditor === undefined) delete process.env.EDITOR
      else process.env.EDITOR = originalEditor
      await rm(root, { recursive: true, force: true })
    },
  }
}

test("custom shortcut fetches the complete transcript, opens the editor, deletes the file and resumes the TUI", async () => {
  const app = await fixture()
  try {
    assert.equal(app.command.id, "session.temp-export")
    assert.equal(app.command.bind, "<leader>y")
    assert.equal(app.command.palette, true)
    assert.deepEqual(app.layer.bindings, ["session.temp-export"])
    assert.equal(app.command.enabled(), true)
    await app.command.run()
    const result = await app.result()
    assert.match(result.body, /Old message outside the UI cache/)
    assert.match(result.body, /\*\*Time elapsed:\*\* 7\.0s/)
    assert.doesNotMatch(result.body, /Hidden/)
    assert.equal(result.cwd, app.cwd)
    assert.equal(result.args[0], "quoted argument")
    assert.equal(result.mode, 0o600)
    await assert.rejects(stat(path.dirname(result.file)), { code: "ENOENT" })
    assert.deepEqual(app.calls, [{ sessionID: "ses_fixture" }])
    assert.deepEqual(app.toasts, [])
    assert.deepEqual(app.events, ["export", "clear-dialog", "suspend-start", "suspend-end", "resume-start", "resume-end", "render"])
  } finally { await app.cleanup() }
})

test("editor failure still deletes the temporary export and restores the terminal before showing an error", async () => {
  const app = await fixture(7)
  try {
    await app.command.run()
    const result = await app.result()
    await assert.rejects(stat(path.dirname(result.file)), { code: "ENOENT" })
    assert.deepEqual(app.events.slice(-3), ["resume-end", "render", "toast"])
    assert.equal(app.toasts[0].message, "Editor exited with code 7")
    assert.equal(app.command.enabled(), true)
  } finally { await app.cleanup() }
})

test("home route, missing EDITOR and export failure do not suspend the TUI", async () => {
  const app = await fixture()
  try {
    app.setRoute({ type: "home" })
    assert.equal(app.command.enabled(), false)
    await app.command.run()
    assert.deepEqual(app.events, [])
    app.setRoute({ type: "session", sessionID: "ses_fixture" })
    delete process.env.EDITOR
    await app.command.run()
    assert.equal(app.toasts[0].message, "$EDITOR is not set")
    process.env.EDITOR = "unused-editor"
    app.ctx.client.experimental.session.export = async () => { throw new Error("Export unavailable") }
    await app.command.run()
    assert.equal(app.toasts[1].message, "Export unavailable")
    assert.deepEqual(app.events, ["toast", "toast"])
  } finally { await app.cleanup() }
})

test("repeated key presses cannot open two editors", async () => {
  const app = await fixture()
  try {
    const original = app.ctx.client.experimental.session.export
    let release
    const gate = new Promise((resolve) => { release = resolve })
    app.ctx.client.experimental.session.export = async (input) => { await gate; return original(input) }
    const pending = app.command.run()
    assert.equal(app.command.enabled(), false)
    await app.command.run()
    release()
    await pending
    assert.equal(app.calls.length, 1)
  } finally { await app.cleanup() }
})
