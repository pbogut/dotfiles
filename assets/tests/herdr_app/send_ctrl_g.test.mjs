import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { test } from "node:test";
import { CtrlGPaint, sendCtrlG } from "../../../dot_config/herdr-app/mods/pbogut-keys/send-ctrl-g.mjs";

test("Ctrl+G follows the initial keyboard state across every possible frame boundary", () => {
  for (const [mode, expected] of [
    ["", "\x07"], ["\x1b[=1;1u", "\x1b[103;5u"],
    ["\x1b[=31;1u", "\x1b[103;5u"], ["\x1b[>4;2m", "\x1b[27;5;103~"],
    ["\x1b[>4;2m\x1b[=1;1u", "\x1b[103;5u"],
    ["\x1b[=1;1u\x1b[=0;1u", "\x07"],
  ]) {
    for (const win32 of ["h", "l"]) {
      const bytes = Buffer.from(`\x18\x1b[=0;1uhello${mode}\x1b[?9001${win32}`);
      for (let split = 0; split < bytes.length; split++) {
        const paint = new CtrlGPaint();
        assert.equal(paint.feed(bytes.subarray(0, split)), null);
        assert.equal(paint.feed(bytes.subarray(split)), expected);
      }
    }
  }
});

test("titles and graphics containing escape sequences cannot change keyboard state", () => {
  for (const [open, close] of [["]", "\x07"], ["]", "\x1b\\"], ["P", "\x1b\\"], ["_", "\x1b\\"]]) {
    const paint = new CtrlGPaint();
    const bytes = Buffer.from(`\x1b${open}title\x1b[=1;1u\x1b[?9001h${close}\x1b[?9001l`);
    for (const byte of bytes.subarray(0, -1)) assert.equal(paint.feed([byte]), null);
    assert.equal(paint.feed(bytes.subarray(-1)), "\x07");
  }
});

async function fakeCore(t, behavior) {
  const directory = await mkdtemp("/tmp/opencode/herdr-input-rpc-");
  t.after(() => rm(directory, { recursive: true, force: true }));
  const core = join(directory, "core.mjs");
  const received = join(directory, "received.jsonl");
  await writeFile(core, `#!${process.execPath}
import { appendFileSync } from "node:fs";
const behavior = ${JSON.stringify(behavior)};
let buffer = Buffer.alloc(0), framed = false;
function send(channel, kind, text) {
  const payload = Buffer.from(text);
  const header = Buffer.alloc(9);
  header.writeUInt32LE(channel);
  header[4] = kind;
  header.writeUInt32LE(payload.length, 5);
  // Exercise partial headers, not just partial terminal sequences.
  process.stdout.write(header.subarray(0, 4));
  setTimeout(() => process.stdout.write(Buffer.concat([header.subarray(4), payload])), 5);
}
process.stdin.on("data", chunk => {
  buffer = Buffer.concat([buffer, chunk]);
  if (!framed) {
    const end = buffer.indexOf(10);
    if (end < 0) return;
    buffer = buffer.subarray(end + 1);
    framed = true;
    process.stdout.write(JSON.stringify({id:1,result:{generation:1,framed:true}}) + "\\n");
  }
  while (buffer.length >= 9) {
    const channel = buffer.readUInt32LE(), kind = buffer[4], length = buffer.readUInt32LE(5);
    if (buffer.length < 9 + length) return;
    const payload = buffer.subarray(9, 9 + length);
    buffer = buffer.subarray(9 + length);
    if (channel === 0) {
      const request = JSON.parse(payload);
      appendFileSync(${JSON.stringify(received)}, JSON.stringify(request.params) + "\\n");
      if (behavior === "error") {
        send(0, 0, JSON.stringify({id:2,error:{message:"No such terminal"}}));
      } else {
        send(0, 0, JSON.stringify({id:2,result:{channel:7}}));
        setTimeout(() => send(7, 0, "x".repeat(256 * 1024)), 15);
      }
    } else if (kind === 1 && payload.readUInt32LE() === 256 * 1024) {
      send(7, 0, "\\x1b[=1;1u\\x1b[?9001l");
    } else if (kind === 0 || kind === 2) {
      appendFileSync(${JSON.stringify(received)}, JSON.stringify([kind,payload.toString("hex")]) + "\\n");
      if (kind === 2 && behavior === "ack") setTimeout(() => send(7, 2, ""), 80);
    }
  }
});
`, { mode: 0o700 });
  return {
    core,
    records: async () => (await readFile(received, "utf8")).trim().split("\n").map(JSON.parse),
  };
}

test("input survives fragmented frames and flow control, then waits for detach acknowledgment", async t => {
  const fixture = await fakeCore(t, "ack");
  const start = performance.now();
  await sendCtrlG("remote/t9", { core: fixture.core });
  assert.ok(performance.now() - start >= 80, "Must wait for CLOSE before reporting success");
  assert.deepEqual(await fixture.records(), [
    { terminal: "remote/t9", cols: 0, rows: 0, history: 0, resumed: true },
    [0, Buffer.from("\x1b[103;5u").toString("hex")],
    [2, ""],
  ]);
});

test("a lost acknowledgment times out without replaying the key", async t => {
  const fixture = await fakeCore(t, "stall");
  await assert.rejects(sendCtrlG("t1", { core: fixture.core, timeout: 300 }), /delivery is uncertain/);
  assert.deepEqual((await fixture.records()).slice(1), [
    [0, Buffer.from("\x1b[103;5u").toString("hex")], [2, ""],
  ]);
});

test("attach errors send no input", async t => {
  const fixture = await fakeCore(t, "error");
  await assert.rejects(sendCtrlG("t1", { core: fixture.core }), /No such terminal/);
  assert.equal((await fixture.records()).length, 1);
});
