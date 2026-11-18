import { spawn } from "node:child_process";
import { pathToFileURL } from "node:url";

// Core's first paint ends its keyboard state with CSI ?9001h/l. Read through
// that trailer, including fragmented frames, before choosing Ctrl+G's encoding.
export class CtrlGPaint {
  state = "";
  sequence = "";
  kitty = false;
  modify = false;
  string = "";

  feed(bytes) {
    for (const byte of bytes) {
      const char = String.fromCharCode(byte);
      if (byte === 0x18 || byte === 0x1a) {
        this.state = "";
      } else if (this.state === "string" || this.state === "string-escape") {
        if ((this.string === "]" && byte === 7) || (this.state === "string-escape" && char === "\\")) {
          this.state = "";
        } else this.state = byte === 0x1b ? "string-escape" : "string";
      } else if (byte === 0x1b) {
        this.state = "escape";
      } else if (this.state === "escape") {
        this.sequence = "";
        this.state = char === "[" ? "csi" : "]PX^_".includes(char) ? "string" : "";
        this.string = char;
      } else if (this.state === "csi") {
        this.sequence += char;
        if (byte >= 0x40 && byte <= 0x7e) {
          this.state = "";
          if (/^=\d+;1u$/.test(this.sequence)) this.kitty = Number(this.sequence.slice(1, -3)) !== 0;
          if (/^>4;[012]m$/.test(this.sequence)) this.modify = this.sequence === ">4;2m";
          if (/^\?9001[hl]$/.test(this.sequence)) {
            // Like the App, Ctrl+G stays a C0 byte in Win32 mode unless Kitty is active.
            return this.kitty ? "\x1b[103;5u" : this.modify ? "\x1b[27;5;103~" : "\x07";
          }
        } else if (this.sequence.length > 128) this.state = "";
      }
    }
    return null;
  }
}

function frame(channel, kind, payload = Buffer.alloc(0)) {
  payload = Buffer.from(payload);
  const header = Buffer.alloc(9);
  header.writeUInt32LE(channel);
  header[4] = kind;
  header.writeUInt32LE(payload.length, 5);
  return Buffer.concat([header, payload]);
}

export function sendCtrlG(terminal, { core = "hc", timeout = 2000 } = {}) {
  if (typeof terminal !== "string" || !terminal) return Promise.reject(new Error("A terminal address is required."));
  return new Promise((resolve, reject) => {
    const child = spawn(core, ["connect"], { stdio: ["pipe", "pipe", "pipe"] });
    const paint = new CtrlGPaint();
    let buffer = Buffer.alloc(0), stderr = "", channel = null;
    let framed = false, sent = false, finished = false;
    const timer = setTimeout(() => finish(new Error(sent
      ? "Core timed out after sending Ctrl+G; delivery is uncertain."
      : "Core timed out before sending Ctrl+G.")), timeout);
    function finish(error) {
      if (finished) return;
      finished = true;
      clearTimeout(timer);
      child.kill();
      if (error) reject(error);
      else resolve();
    }
    const rpc = (id, method, params) => JSON.stringify({ jsonrpc: "2.0", id, method, params });
    function reply(payload, id) {
      const message = JSON.parse(payload);
      if (message.id !== id) throw new Error("Unexpected Core reply.");
      if (message.error) throw new Error(message.error.message);
      return message.result;
    }
    child.once("error", finish);
    child.stdin.on("error", finish);
    child.stdout.on("error", finish);
    child.stderr.on("data", chunk => { stderr = (stderr + chunk).slice(-4096); });
    child.once("close", () => finish(new Error(stderr.trim() || "Core disconnected before acknowledging Ctrl+G.")));
    child.stdout.on("data", chunk => {
      if (finished) return;
      try {
        buffer = Buffer.concat([buffer, chunk]);
        if (!framed) {
          const end = buffer.indexOf(10);
          if (end < 0) {
            if (buffer.length > 16 * 1024 * 1024) throw new Error("Core handshake is too large.");
            return;
          }
          const hello = reply(buffer.subarray(0, end), 1);
          if (hello.generation !== 1 || !hello.framed) throw new Error("Core does not support framed generation 1.");
          buffer = buffer.subarray(end + 1);
          framed = true;
          child.stdin.write(frame(0, 0, rpc(2, "terminal.attach", {
            terminal, cols: 0, rows: 0, history: 0, resumed: true,
          })));
        }
        while (buffer.length >= 9) {
          const ch = buffer.readUInt32LE(), kind = buffer[4], length = buffer.readUInt32LE(5);
          if (length > 16 * 1024 * 1024) throw new Error("Core frame is too large.");
          if (buffer.length < 9 + length) return;
          const payload = buffer.subarray(9, 9 + length);
          buffer = buffer.subarray(9 + length);
          if (ch === 0 && kind === 0) {
            channel = reply(payload, 2).channel;
            if (!Number.isInteger(channel) || channel <= 0) throw new Error("Core returned an invalid attach channel.");
          } else if (ch === channel && kind === 0 && !sent) {
            const credit = Buffer.alloc(4);
            credit.writeUInt32LE(length);
            child.stdin.write(frame(channel, 1, credit));
            const key = paint.feed(payload);
            if (key !== null) {
              sent = true;
              // DATA is human input. CLOSE follows it on the same ordered stream.
              child.stdin.write(Buffer.concat([frame(channel, 0, key), frame(channel, 2)]));
            }
          } else if (ch === channel && kind === 2) {
            finish(sent && length === 0 ? null : new Error("Terminal closed before Ctrl+G was acknowledged."));
            return;
          }
        }
      } catch (error) { finish(error); }
    });
    child.stdin.write(rpc(1, "hello", { generation: 1, framed: true }) + "\n");
  });
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  sendCtrlG(process.argv[2], { core: process.argv[3] || "hc" }).catch(error => {
    console.error(error.message);
    process.exitCode = 1;
  });
}
