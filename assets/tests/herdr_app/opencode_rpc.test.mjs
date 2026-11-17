import assert from "node:assert/strict"
import { mkdtemp, writeFile, rm } from "node:fs/promises"
import { join } from "node:path"
import { test } from "node:test"
import { core } from "../../../dot_config/opencode/extensions/herdr-subject/app-session.js"

test("keeps hc connect input open until the reply and returns native error kinds", async (t) => {
  const directory = await mkdtemp("/tmp/opencode/herdr-rpc-test-")
  const path = process.env.PATH
  process.env.PATH = `${directory}:${path}`
  t.after(async () => {
    process.env.PATH = path
    await rm(directory, { recursive: true, force: true })
  })
  await writeFile(join(directory, "hc"), `#!/usr/bin/env node
process.stdin.once("data", chunk => {
  const request = JSON.parse(chunk);
  setTimeout(() => {
    const result = request.method === "doc.set"
      ? { error: { message: "Stale version", data: { kind: "conflict" } } }
      : { result: { value: null, version: 0 } };
    process.stdout.write(JSON.stringify({ id: request.id, ...result }) + "\\n");
  }, 50);
});
process.stdin.on("end", () => process.exit(0));
`, { mode: 0o700 })
  assert.deepEqual(await core("doc.get", { name: "test" }), { value: null, version: 0 })
  await assert.rejects(core("doc.set", { name: "test" }), { kind: "conflict" })
})
