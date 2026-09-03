import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import net from "node:net";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterEach, test } from "node:test";

const root = new URL("../../../", import.meta.url);
const sourceUrl = new URL("dot_config/opencode/herdr-tui-session.js", root);
const source = await readFile(sourceUrl, "utf8");
const pluginModule = await import(
  `data:text/javascript;base64,${Buffer.from(source).toString("base64")}`
);

const originalEnv = {
  HERDR_ENV: process.env.HERDR_ENV,
  HERDR_PANE_ID: process.env.HERDR_PANE_ID,
  HERDR_SOCKET_PATH: process.env.HERDR_SOCKET_PATH,
};
const cleanups = [];

afterEach(async () => {
  while (cleanups.length > 0) {
    await cleanups.pop()();
  }
  for (const [name, value] of Object.entries(originalEnv)) {
    if (value === undefined) {
      delete process.env[name];
    } else {
      process.env[name] = value;
    }
  }
});

function fakeApi(session) {
  let dispose = () => {};
  return {
    api: {
      route: { current: { name: "session", params: { sessionID: session.id } } },
      state: { session: { get: () => session } },
      lifecycle: { onDispose: (handler) => (dispose = handler) },
    },
    dispose: () => dispose(),
  };
}

async function socketServer() {
  const socketPath = join(tmpdir(), `herdr-opencode-${process.pid}-${Date.now()}.sock`);
  const requests = [];
  const server = net.createServer((client) => {
    let input = "";
    client.on("data", (chunk) => {
      input += chunk;
      const newline = input.indexOf("\n");
      if (newline === -1) return;
      requests.push(JSON.parse(input.slice(0, newline)));
      client.end('{"result":{}}\n');
    });
  });
  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(socketPath, resolve);
  });
  cleanups.push(
    () => new Promise((resolve, reject) => server.close((error) => (error ? reject(error) : resolve())))
  );
  return { socketPath, requests };
}

test("reports only the selected root session", async () => {
  const { socketPath, requests } = await socketServer();
  process.env.HERDR_ENV = "1";
  process.env.HERDR_PANE_ID = "w1:p1";
  process.env.HERDR_SOCKET_PATH = socketPath;
  const tui = fakeApi({ id: "ses_exact_123" });

  await pluginModule.default.tui(tui.api);
  tui.dispose();

  assert.equal(requests.length, 1);
  assert.deepEqual(requests[0], {
    id: requests[0].id,
    method: "pane.report_agent_session",
    params: {
      pane_id: "w1:p1",
      source: "herdr:opencode",
      agent: "opencode",
      agent_session_id: "ses_exact_123",
      session_start_source: "select",
    },
  });
  assert.doesNotMatch(source, /method:\s*["']pane\.report_agent["']/);
});

test("does not report a selected child session", async () => {
  const { socketPath, requests } = await socketServer();
  process.env.HERDR_ENV = "1";
  process.env.HERDR_PANE_ID = "w1:p1";
  process.env.HERDR_SOCKET_PATH = socketPath;
  const tui = fakeApi({ id: "ses_child", parentID: "ses_root" });

  await pluginModule.default.tui(tui.api);
  await new Promise((resolve) => setTimeout(resolve, 125));
  tui.dispose();

  assert.equal(requests.length, 0);
});
